import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

class PendingOrdersPage extends StatefulWidget {
  const PendingOrdersPage({super.key});

  @override
  State<PendingOrdersPage> createState() => _PendingOrdersPageState();
}

class _PendingOrdersPageState extends State<PendingOrdersPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
  }

  Future<void> _fetchPendingOrders() async {
    try {
      // 1. Fetch Orders
      final response = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(response);

      // 2. Collect Seller IDs
      final Set<String> sellerIds = {};
      for (var order in orders) {
        if (order['seller_id'] != null) {
          sellerIds.add(order['seller_id']);
        }
      }

      // 3. Fetch Profiles manually
      Map<String, String> sellerNames = {};
      if (sellerIds.isNotEmpty) {
        final profilesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', sellerIds.toList());
        
        for (var p in profilesResponse) {
          sellerNames[p['id']] = p['full_name'] ?? 'Unknown';
        }
      }

      // 4. Attach names to orders
      for (var order in orders) {
        if (order['seller_id'] != null) {
          order['seller_name_display'] = sellerNames[order['seller_id']];
        }
      }

      if (mounted) {
        setState(() {
          _pendingOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processOrder(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật đơn hàng sang: $newStatus')),
        );
        _fetchPendingOrders(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn Hàng Chờ Duyệt')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingOrders.isEmpty
              ? const Center(child: Text('Không có đơn hàng chờ duyệt'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingOrders.length,
                  separatorBuilder: (c, i) => const Gap(16),
                  itemBuilder: (context, index) {
                    final order = _pendingOrders[index];
                    final date = DateTime.parse(order['created_at']).toLocal();
                    final total = (order['total_amount'] as num).toDouble();
                    final items = (order['order_items'] as List<dynamic>?) ?? [];

                    return Card(
                      child: ExpansionTile(
                        title: Text('${order['customer_name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total)} - ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                            ),
                             if (order['seller_name_display'] != null)
                               Text(
                                 'Sale: ${order['seller_name_display']}',
                                 style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                               ),
                          ],
                        ),
                         children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SĐT: ${order['customer_phone']}'),
                                Text('Địa chỉ: ${order['customer_address']}'),
                                const Gap(8),
                                const Text('Sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...items.map((item) => Text('- ${item['product_name']} x${item['quantity']}')),
                                const Gap(16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _processOrder(order['id'].toString(), 'cancelled'),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Huỷ Đơn'),
                                    ),
                                    const Gap(12),
                                    ElevatedButton(
                                      onPressed: () => _processOrder(order['id'].toString(), 'confirmed'),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                                      child: const Text('Xác Nhận'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
