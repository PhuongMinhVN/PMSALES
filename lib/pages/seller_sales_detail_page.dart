import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SellerSalesDetailPage extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerSalesDetailPage({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerSalesDetailPage> createState() => _SellerSalesDetailPageState();
}

class _SellerSalesDetailPageState extends State<SellerSalesDetailPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSellerOrders();
  }

  Future<void> _fetchSellerOrders() async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('seller_id', widget.sellerId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: false);
      
      final data = List<Map<String, dynamic>>.from(response);
      
      double total = 0;
      for (var order in data) {
         total += (order['total_amount'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _orders = data;
          _totalAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _openMap(String? link) async {
    if (link == null || link.isEmpty) return;
    try {
      if (await canLaunchUrlString(link)) {
        await launchUrlString(link);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở bản đồ')));
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('Chi Tiết: ${widget.sellerName}')),
      body: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Text('Tổng doanh số', style: TextStyle(color: Colors.grey.shade400)),
                const Gap(4),
                Text(
                  currencyFormat.format(_totalAmount),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF03DAC6)),
                ),
                const Gap(4),
                Text('${_orders.length} đơn hàng', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Order List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('Chưa có đơn hàng nào.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (c, i) => const Gap(12),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final date = DateTime.parse(order['created_at']).toLocal();
                          final total = (order['total_amount'] as num).toDouble();
                          final customerName = order['customer_name'] ?? 'Khách lạ';
                          final customerPhone = order['customer_phone'] ?? '---';
                          final address = order['customer_address'] ?? 'Tại cửa hàng';
                          final mapLink = order['google_maps_link'];

                          return Card(
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateFormat.format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    currencyFormat.format(total),
                                    style: const TextStyle(color: Color(0xFFCF6679), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 14, color: Colors.grey),
                                        const Gap(4),
                                        Text(customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    const Gap(4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                                        const Gap(4),
                                        Text(customerPhone),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ĐỊA CHỈ & VỊ TRÍ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      const Gap(8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Color(0xFF03DAC6)),
                                          const Gap(8),
                                          Expanded(child: Text(address)),
                                        ],
                                      ),
                                      if (mapLink != null && mapLink.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: InkWell(
                                            onTap: () => _openMap(mapLink),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.map, size: 16, color: Colors.blue),
                                                const Gap(8),
                                                const Text(
                                                  'Xem trên Google Maps',
                                                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              ],
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
