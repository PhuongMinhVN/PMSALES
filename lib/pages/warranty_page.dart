import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'checkout_page.dart';
import 'scan_qr_page.dart';

class WarrantyPage extends StatefulWidget {
  const WarrantyPage({super.key});

  @override
  State<WarrantyPage> createState() => _WarrantyPageState();
}

class _WarrantyPageState extends State<WarrantyPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  void _scanQr() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanQrPage()),
    );
    if (result != null && result is String) {
      _searchController.text = result;
      _searchWarranty();
    }
  }

  Future<void> _searchWarranty() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
      _hasSearched = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .or('customer_phone.ilike.%$query%, customer_name.ilike.%$query%, id.eq.${int.tryParse(query) ?? -1}, qr_code.eq.$query')
          .order('created_at', ascending: false);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tra cứu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _extendWarranty(Map<String, dynamic> item) async {
    final double priceAtSale = (item['price_at_sale'] as num?)?.toDouble() ?? 0.0;
    final double extensionFee = priceAtSale * 0.20;
    final formattedFee = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(extensionFee);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gia Hạn Bảo Hành'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có muốn gia hạn thêm 1 năm bảo hành cho sản phẩm này không?'),
            const Gap(16),
            Text('Phí gia hạn (20%): $formattedFee', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đồng Ý')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentEnd = DateTime.parse(item['warranty_end_date']);
      final newEnd = DateTime(currentEnd.year + 1, currentEnd.month, currentEnd.day);

      await Supabase.instance.client
          .from('order_items')
          .update({'warranty_end_date': newEnd.toIso8601String()})
          .eq('id', item['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gia hạn thành công!')));
        _searchWarranty();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy').format(date);
    } catch(e) {
      return dateStr;
    }
  }

  String _maskPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    if (phone.length <= 4) return phone;
    return '******${phone.substring(phone.length - 4)}';
  }


  void _goToCheckout() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutPage(cart: context.read<CartProvider>().cart)),
    );
     if (result == true) {
      if (mounted) context.read<CartProvider>().clearCart();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra Cứu Bảo Hành'),
        actions: [

          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            tooltip: 'Về Trang Chủ',
          ),
        ],
      ),
      floatingActionButton: context.watch<CartProvider>().cart.isNotEmpty ? FloatingActionButton.extended(
        onPressed: _goToCheckout,
        label: Text('Giỏ hàng (${context.watch<CartProvider>().cart.length})'),
        icon: const Icon(Icons.shopping_cart_checkout),
      ) : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập SĐT, Tên, Mã đơn hoặc Quét QR',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchWarranty(),
                  ),
                ),
                const Gap(8),
                IconButton.filled(
                  onPressed: _scanQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Quét QR',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: _hasSearched
                            ? const Text('Không tìm thấy đơn hàng nào.')
                            : const Text('Nhập thông tin để tra cứu'),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final order = _searchResults[index];
                          final items = (order['order_items'] as List?) ?? [];
                          final date = DateTime.parse(order['created_at']).toLocal();

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              title: Text('Đơn hàng #${order['id']} - ${order['customer_name']}'),
                              subtitle: Text(
                                'Ngày mua: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}\nSĐT: ${_maskPhoneNumber(order['customer_phone'] ?? '')}',
                              ),
                              children: items.map<Widget>((item) {
                                final warrantyEnd = DateTime.parse(item['warranty_end_date']).toLocal();
                                final isExpired = DateTime.now().isAfter(warrantyEnd);
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const Gap(4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Hết hạn: ${_formatDate(item['warranty_end_date'])}'),
                                          if (isExpired)
                                            item['price_at_sale'] != null 
                                            ? ElevatedButton.icon(
                                                onPressed: () => _extendWarranty(item),
                                                icon: const Icon(Icons.update, size: 16),
                                                label: const Text('Gia hạn'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                              )
                                            : const Chip(label: Text('Hết hạn'), backgroundColor: Colors.redAccent)
                                          else
                                             const Chip(label: Text('Còn BH'), backgroundColor: Colors.greenAccent),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
