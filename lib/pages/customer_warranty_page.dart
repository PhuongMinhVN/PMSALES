import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'scan_qr_page.dart';

class CustomerWarrantyPage extends StatefulWidget {
  const CustomerWarrantyPage({super.key});

  @override
  State<CustomerWarrantyPage> createState() => _CustomerWarrantyPageState();
}

class _CustomerWarrantyPageState extends State<CustomerWarrantyPage> {
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
      // Use RPC function for public access (bypassing RLS safely)
      final response = await Supabase.instance.client
          .rpc('search_orders_warranty', params: {'keyword': query});

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        String message = 'Lỗi tra cứu: $e';
        if (e.toString().contains('function search_orders_warranty does not exist')) {
          message = 'Lỗi: Chưa cài đặt hàm tìm kiếm trên Database. Vui lòng chạy file create_warranty_rpc.sql';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra Cứu Bảo Hành'),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (Supabase.instance.client.auth.currentUser != null) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            icon: const Icon(Icons.home),
            label: const Text('Trang Chủ'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Nhập thông tin bên dưới để kiểm tra thời hạn bảo hành sản phẩm của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Nhập SĐT, Tên, hoặc Quét QR',
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
                const Gap(16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchWarranty,
                   style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                    : const Text('Tra Cứu'),
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
                            ? const Text('Không tìm thấy đơn hàng nào phù hợp.')
                            : const SizedBox(),
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
                              title: Text('Đơn hàng #${order['qr_code'] ?? order['id']}'),
                              subtitle: Text(
                                'Khách hàng: ${order['customer_name']}\nNgày mua: ${DateFormat('dd/MM/yyyy').format(date)}',
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
                                          isExpired
                                            ? const Chip(label: Text('Đã hết hạn'), backgroundColor: Colors.redAccent, labelStyle: TextStyle(fontSize: 12))
                                            : const Chip(label: Text('Còn bảo hành'), backgroundColor: Colors.greenAccent, labelStyle: TextStyle(color: Colors.black, fontSize: 12)),
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
