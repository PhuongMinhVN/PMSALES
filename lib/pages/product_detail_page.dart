import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'add_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final Function(Product) onAddToCart;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late int _selectedWarrantyMonths;
  bool _includeInstallation = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedWarrantyMonths = widget.product.warrantyPeriodMonths;
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        if (mounted) {
           setState(() {
             _isAdmin = data['role'] == 'admin';
           });
        }
      } catch (_) {}
    }
  }

  double get _finalPrice {
    // If selected 24 months and default is NOT 24 (meaning it's an extension), add 20%
    if (_selectedWarrantyMonths == 24 && widget.product.warrantyPeriodMonths != 24) {
      return widget.product.price * 1.20;
    }
    return widget.product.price;
  }

  String _formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            tooltip: 'Về Trang Chủ',
          ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => AddProductPage(productToClone: widget.product)),
                 );
              },
              tooltip: 'Sao Chép Sản Phẩm',
            ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                 final result = await Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => AddProductPage(productToEdit: widget.product)),
                 );
                 // If updated/deleted, we should probably pop or refresh. 
                 // If deleted (result == true/false?), let's assume if it returns true, we need to refresh or pop.
                 // Actually EditPage deletes and pops to Home.
                 // If update happens, we might want to refresh THIS page or pop.
                 // EditPage implementation: Navigator.pop(context, true) on update.
                 if (result == true) {
                    Navigator.pop(context, true); // Signal to Home to refresh
                 }
              },
              tooltip: 'Sửa Sản Phẩm',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 300,
                    color: Colors.grey.shade900,
                    child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image, size: 64, color: Colors.grey),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.product.category != null)
                          Chip(
                            label: Text(widget.product.category!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFF03DAC6),
                          ),
                        const Gap(8),
                        Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Gap(8),
                        Text(
                          _formatCurrency(_finalPrice),
                          style: const TextStyle(fontSize: 22, color: Color(0xFFCF6679), fontWeight: FontWeight.bold),
                        ),
                        const Gap(16),
                        
                        // Warranty Selection
                        const Text('Thời gian bảo hành:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Gap(8),
                        DropdownButtonFormField<int>(
                          value: _selectedWarrantyMonths,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ([1, 6, 12, 24, widget.product.warrantyPeriodMonths]
                              .toSet()
                              .toList()
                              ..sort()
                            ).map<DropdownMenuItem<int>>((months) {
                                return DropdownMenuItem<int>(
                                  value: months,
                                  child: Text('$months Tháng${months == widget.product.warrantyPeriodMonths ? ' (Mặc định)' : ''}'),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedWarrantyMonths = val);
                          },
                        ),
                        const Gap(16),
                        


                        const Gap(24),
                        const Divider(),
                        const Text(
                          'Thông số kỹ thuật & Tính năng',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Gap(8),
                        Text(
                          widget.product.technicalSpecs != null && widget.product.technicalSpecs!.isNotEmpty
                              ? widget.product.technicalSpecs!
                              : 'Đang cập nhật...',
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: () {
                   final cartProduct = widget.product.copyWith(
                     cartWarrantyMonths: _selectedWarrantyMonths,
                     cartIncludesInstallation: false,
                     cartSalePrice: _finalPrice,
                   );
                   widget.onAddToCart(cartProduct);
                   Navigator.pop(context); 
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('Thêm Vào Giỏ - ${_formatCurrency(_finalPrice)}', style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
