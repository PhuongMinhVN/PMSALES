import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/product.dart';
import 'order_success_page.dart';  
import '../services/invoice_service.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

// Helper class for Cart Logic
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => (product.cartSalePrice ?? product.price) * quantity;
}

class CheckoutPage extends StatefulWidget {
  final List<Product> cart;
  const CheckoutPage({super.key, required this.cart});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapLinkController = TextEditingController();
  
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double _discountPercent = 0;

  @override
  void initState() {
    super.initState();
    _processCart();
  }

  void _processCart() {
    // Group identical products
    Map<String, CartItem> grouped = {};

    for (var product in widget.cart) {


      final key = '${product.id}_${product.cartIncludesInstallation}';
      
      if (grouped.containsKey(key)) {
        grouped[key]!.quantity++;
      } else {
        grouped[key] = CartItem(product: product, quantity: 1);
      }
    }
    
    _cartItems = grouped.values.toList();
  }

  double get _originalTotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _total => _originalTotal * (1 - _discountPercent / 100);

  void _increment(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void _decrement(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        // Optional: Remove item if qty goes to 0? 
        // For checkout, usually we keep 1 or ask to remove. 
        // Let's keep min 1 for now.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số lượng tối thiểu là 1')));
      }
    });
  }

  void _deleteItem(CartItem item) {
    setState(() {
      _cartItems.remove(item);
      // Note: This only removes from local internal list for this session.
      // If user goes back, `widget.cart` might still have it unless we lift state up.
      // For now, this is sufficient for Checkout manipulation.
    });
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Vui lòng bật định vị (Location Services) trên thiết bị.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền vị trí bị từ chối vĩnh viễn. Hãy vào cài đặt bật lại.');
      }

      Position? position;
      
      try {
        // getLastKnownPosition is not supported on Web
        // We can just skip it for web or catch the specific error, 
        // but 'kIsWeb' check is cleaner if we import foundation.
        // For now, let's just use try-catch around it to fail gracefully to getCurrentPosition
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {
        // Ignore error (e.g. Unsupported operation on Web) and proceed to getCurrentPosition
      }

      if (position == null) {
        // Use LocationSettings with balanced accuracy for faster results on Web/Desktop
        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.medium, 
          distanceFilter: 100,
          timeLimit: Duration(seconds: 10), 
        );

        // Force a Dart-side timeout in case the plugin hangs
        position = await Geolocator.getCurrentPosition(locationSettings: locationSettings)
            .timeout(const Duration(seconds: 10));
      }
      
      final googleMapsUrl = 'https://www.google.com/maps/?q=${position.latitude},${position.longitude}';
      
      if (mounted) {
        setState(() {
          _mapLinkController.text = googleMapsUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã lấy vị trí thành công!'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Lỗi lấy vị trí: $e';
        if (e.toString().contains('User denied')) msg = 'Bạn đã từ chối cấp quyền vị trí.';
        if (e.toString().contains('TimeoutException')) msg = 'Không thể lấy vị trí (quá thời gian). Kiểm tra kết nối mạng.';
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      // 1. Create Order
      final orderRes = await Supabase.instance.client
          .from('orders')
          .insert({
            'customer_name': _nameController.text.trim(),
            'customer_phone': _phoneController.text.trim(),
            'customer_address': _addressController.text.trim(),
            'google_maps_link': _mapLinkController.text.trim().isEmpty ? null : _mapLinkController.text.trim(),
            'total_amount': _total,
            'created_by': user.id,
            'seller_id': user.id, 
            'status': 'pending', // Explicitly set as pending
          })
          .select()
          .single();
      
      final orderId = orderRes['id'];
      final qrCode = orderId.toString(); 

      await Supabase.instance.client
          .from('orders')
          .update({'qr_code': qrCode})
          .eq('id', orderId);

      // 2. Create Order Items (Using Grouped Items)
      final List<Map<String, dynamic>> itemsPayload = [];
      final List<Map<String, dynamic>> invoiceItems = [];

      for (var item in _cartItems) {
        final product = item.product;
        // Default warranty is 12 months if not specified or 0
        int months = product.cartWarrantyMonths ?? product.warrantyPeriodMonths;
        if (months <= 0) months = 12;
        final hasInstallation = product.cartIncludesInstallation ?? false;
        final price = product.cartSalePrice ?? product.price; 
        
        // Calculate Warranty End Date (Accurate Calendar Months)
        final now = DateTime.now();
        // DateTime constructor handles month overflow (e.g., month 13 -> year + 1, month 1)
        final endDate = DateTime(now.year, now.month + months, now.day, now.hour, now.minute); 
        
        String finalName = product.name;
        if (hasInstallation) {
          finalName += ' (Có thi công)';
        }
        
        itemsPayload.add({
          'order_id': orderId,
          'product_id': int.tryParse(product.id), // Null if service (temp ID)
          'product_name': finalName, 
          'price_at_sale': price,
          'quantity': item.quantity, // Insert Quantity
          'warranty_end_date': endDate.toIso8601String(),
          'is_service': int.tryParse(product.id) == null || product.category == 'Dịch vụ',
        });

        invoiceItems.add({
           'name': finalName,
           'warranty': '$months tháng',
           'quantity': item.quantity,
           'price': price,
           'total': item.total,
        });
      }

      await Supabase.instance.client.from('order_items').insert(itemsPayload);

      // 3. Generate Invoice PDF
      String sellerName = 'Sale Staff';
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();
        if (profile['full_name'] != null) sellerName = profile['full_name'];
      } catch (_) {}

      if (mounted) {
         try {
           await InvoiceService.generateAndPrint(
            orderId: qrCode,
            date: DateTime.now(),
            sellerName: sellerName,
            customerName: _nameController.text,
            customerPhone: _phoneController.text,
            customerAddress: _addressController.text,
            items: invoiceItems,
            totalAmount: _total,
            discountPercent: _discountPercent,
          );
         } catch (e) {
           debugPrint('Printing error: $e');
           if (mounted) {
             String msg = 'Đơn hàng thành công, nhưng lỗi in PDF: $e';
             if (e.toString().contains('MissingPluginException')) {
               msg = 'Đơn hàng thành công. Vui lòng KHỞI ĐỘNG LẠI ứng dụng để kích hoạt tính năng in.';
             }
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
           }
         }
      }

      if (mounted) {
        // Clear cart after success
        context.read<CartProvider>().clearCart();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrderSuccessPage(orderId: qrCode)),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo đơn hàng: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán'),
         actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            tooltip: 'Về Trang Chủ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Tổng Thanh Toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                      const Gap(4),
                      if (_discountPercent > 0)
                        Text(
                          _formatCurrency(_originalTotal),
                          style: const TextStyle(fontSize: 18, color: Colors.grey, decoration: TextDecoration.lineThrough),
                        ),
                      Text(
                        _formatCurrency(_total),
                        style: const TextStyle(fontSize: 28, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                      const Gap(8),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          children: [
                            _buildDiscountChip(0),
                            const Gap(8),
                            _buildDiscountChip(5),
                            const Gap(8),
                            _buildDiscountChip(10),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Text('${_cartItems.fold(0, (sum, i) => sum + i.quantity)} sản phẩm', style: const TextStyle(color: Colors.grey)),
                      const Gap(16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.blue),
                            const Gap(8),
                            Text(
                              'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              const Text('Danh Sách Sản Phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(8),
              
              // Product List with Quantity Controls
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _cartItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  final product = item.product;
                  final hasInstallation = product.cartIncludesInstallation ?? false;
                  final months = product.cartWarrantyMonths ?? product.warrantyPeriodMonths;
                  
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image (Optional, if product has it)
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
                          child: product.imageUrl != null 
                             ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(product.imageUrl!, fit: BoxFit.cover))
                             : const Icon(Icons.shopping_bag, color: Colors.grey),
                        ),
                        const Gap(12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const Gap(4),
                               Text(
                                'BH: $months tháng',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Gap(8),
                              InkWell(
                                onTap: () {
                                   setState(() {
                                      final newVal = !(product.cartIncludesInstallation ?? false);
                                      product.cartIncludesInstallation = newVal;
                                      product.cartSalePrice = product.price + (newVal ? 200000 : 0);
                                   });
                                },
                                child: Row(
                                  children: [
                                     SizedBox(
                                       width: 24, height: 24,
                                       child: Checkbox(
                                         value: hasInstallation,
                                         onChanged: (val) {
                                            setState(() {
                                              product.cartIncludesInstallation = val;
                                              product.cartSalePrice = product.price + ((val ?? false) ? 200000 : 0);
                                            });
                                         },
                                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                         side: const BorderSide(color: Colors.grey), 
                                       ),
                                     ),
                                     const Gap(8),
                                     const Text('Thi công lắp đặt (+200k)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
                                  ],
                                ),
                              ),
                              const Gap(4),
                              Text(_formatCurrency((product.cartSalePrice ?? product.price)), style: const TextStyle(color: Color(0xFFCF6679), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        // Qty Controller
                        Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _decrement(item),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  color: Colors.grey,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade600),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  onPressed: () => _increment(item),
                                  icon: const Icon(Icons.add_circle_outline),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  color: Color(0xFF10B981),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _deleteItem(item),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Xoá sản phẩm',
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),

              const Gap(32),
              const Text('Thông Tin Khách Hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(16),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      try {
                        final res = await Supabase.instance.client.from('orders')
                            .select('customer_name, customer_phone, customer_address')
                            .or('customer_name.ilike.%${textEditingValue.text}%, customer_phone.ilike.%${textEditingValue.text}%')
                            .order('created_at', ascending: false)
                            .limit(10);
                        
                        // Local Deduplication
                        final List<Map<String, dynamic>> distinct = [];
                        final seen = <String>{};
                        for (var r in res) {
                          final phone = r['customer_phone'] ?? '';
                          // Key by phone primarily, or name if phone is empty (unlikely for orders)
                          final key = phone.isEmpty ? (r['customer_name'] ?? '') : phone;
                          if (key.isNotEmpty && !seen.contains(key)) {
                            seen.add(key);
                            distinct.add(r);
                          }
                        }
                        return distinct;
                      } catch (e) {
                         return const Iterable<Map<String, dynamic>>.empty();
                      }
                    },
                    displayStringForOption: (option) => '${option['customer_name']} - ${option['customer_phone']}',
                    onSelected: (Map<String, dynamic> selection) {
                       setState(() {
                         _nameController.text = selection['customer_name'] ?? '';
                         _phoneController.text = selection['customer_phone'] ?? '';
                         _addressController.text = selection['customer_address'] ?? '';
                       });
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã điền thông tin khách hàng cũ')));
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Tìm khách cũ (Tên / SĐT)',
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Nhập để tìm kiếm...',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  leading: const Icon(Icons.history, color: Colors.grey),
                                  title: Text(option['customer_name'] ?? '', style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(option['customer_phone'] ?? '', style: const TextStyle(color: Colors.white70)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
              const Gap(16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên Khách Hàng', prefixIcon: Icon(Icons.person)),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên' : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số Điện Thoại', prefixIcon: Icon(Icons.phone)),
                validator: (v) => v == null || v.isEmpty ? 'Nhập SĐT' : null,
              ),
               const Gap(16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa Chỉ', prefixIcon: Icon(Icons.location_on)),
                validator: (v) => v == null || v.isEmpty ? 'Nhập địa chỉ' : null,
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mapLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Link Google Map', 
                        prefixIcon: Icon(Icons.map),
                        helperText: 'Tự động lấy khi nhấn nút',
                      ),
                    ),
                  ),
                  const Gap(8),
                  IconButton.filledTonal(
                    onPressed: _isGettingLocation ? null : _getLocation,
                    icon: _isGettingLocation 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.my_location),
                    tooltip: 'Lấy vị trí hiện tại',
                  ),
                ],
              ),
              const Gap(32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                 style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 4,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Xác Nhận Đơn Hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDiscountChip(double percent) {
    final isSelected = _discountPercent == percent;
    return ChoiceChip(
      label: Text(percent == 0 ? 'Không giảm' : '-${percent.toInt()}%'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _discountPercent = percent);
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.white),
    );
  }
}
