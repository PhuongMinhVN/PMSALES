import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn Hàng Của Tôi'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF03DAC6),
          indicatorColor: const Color(0xFF03DAC6),
          tabs: const [
            Tab(text: 'Đang chờ xác nhận'),
            Tab(text: 'Lịch sử đơn hàng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MyOrdersList(statusFilter: 'pending'),
          MyOrdersList(statusFilter: 'other'), // confirmed or cancelled
        ],
      ),
    );
  }
}

class MyOrdersList extends StatefulWidget {
  final String statusFilter;
  const MyOrdersList({super.key, required this.statusFilter});

  @override
  State<MyOrdersList> createState() => _MyOrdersListState();
}

class _MyOrdersListState extends State<MyOrdersList> {
  // Use Stream to get real-time updates when Admin confirms
  final _ordersStream = Supabase.instance.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('created_by', Supabase.instance.client.auth.currentUser!.id)
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final allOrders = snapshot.data ?? [];
        
        // Filter locally because Stream filter capabilities are limited compared to simple Postgrest
        final orders = allOrders.where((order) {
           final status = (order['status'] ?? 'pending') as String;
           if (widget.statusFilter == 'pending') {
             return status == 'pending';
           } else {
             return status != 'pending';
           }
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                const Gap(16),
                Text(
                  widget.statusFilter == 'pending' 
                  ? 'Không có đơn hàng nào đang chờ' 
                  : 'Chưa có lịch sử đơn hàng',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (c, i) => const Gap(12),
          itemBuilder: (context, index) {
            final order = orders[index];
            final date = DateTime.parse(order['created_at']).toLocal();
            final total = (order['total_amount'] as num).toDouble();
            final status = order['status'] ?? 'pending';
            
            Color statusColor = Colors.orange;
            String statusText = 'Đang chờ duyệt';
            
            if (status == 'confirmed') {
              statusColor = Colors.green;
              statusText = 'Đã hoàn thành';
            } else if (status == 'cancelled') {
              statusColor = Colors.red;
              statusText = 'Đã huỷ';
            }

            return Card(
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                       NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total),
                       style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03DAC6)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        statusText, 
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Gap(4),
                     Text('Khách: ${order['customer_name']}'),
                     Text(DateFormat('dd/MM/yyyy HH:mm').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                onTap: () {
                   // Show basic details dialog
                   showDialog(
                     context: context, 
                     builder: (context) => AlertDialog(
                       title: Text('Đơn hàng #${order['id']}'),
                       content: Column(
                         mainAxisSize: MainAxisSize.min,
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text('Khách hàng: ${order['customer_name']}'),
                            Text('SĐT: ${order['customer_phone']}'),
                            Text('Địa chỉ: ${order['customer_address']}'),
                            const Gap(8),
                            Text('Trạng thái: $statusText', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            const Gap(16),
                            const Text('Sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
                            // Note: To show items, we would need to fetch them. 
                            // Since this is a simple list view, we keep it light.
                            // Real app would navigate to Detail Page.
                            const Text('(Xem chi tiết trong lịch sử admin hoặc quét QR)'),
                         ],
                       ),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                       ],
                     ),
                   );
                },
              ),
            );
          },
        );
      },
    );
  }
}
