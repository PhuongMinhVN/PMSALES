import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'seller_sales_detail_page.dart';

class SalesStatisticsPage extends StatefulWidget {
  const SalesStatisticsPage({super.key});

  @override
  State<SalesStatisticsPage> createState() => _SalesStatisticsPageState();
}

class _SalesStatisticsPageState extends State<SalesStatisticsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sellerStats = [];
  
  // Global Stats
  int _uniqueCustomers = 0;
  double _totalRevenue = 0;
  int _productsSold = 0;
  int _servicesSold = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // 1. Fetch Profiles (Sellers/Admins)
      final profilesResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, role')
          .or('role.eq.sales,role.eq.admin');
      final profiles = List<Map<String, dynamic>>.from(profilesResponse);
      
      // 2. Fetch Orders (For Revenue, Customers, and Seller Stats)
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('seller_id, total_amount, customer_phone')
          .eq('status', 'confirmed');
      final orders = List<Map<String, dynamic>>.from(ordersResponse);

      // 3. Fetch Order Items Count (Products vs Services)
      // Service items have is_service == true
      final servicesCount = await Supabase.instance.client
          .from('order_items')
          .count(CountOption.exact)
          .eq('is_service', true);
      
      final productsCount = await Supabase.instance.client
          .from('order_items')
          .count(CountOption.exact)
          .eq('is_service', false);

      _servicesSold = servicesCount;
      _productsSold = productsCount;

      // 4. Calculate Global Stats
      Set<String> uniquePhones = {};
      double revenue = 0;
      
      Map<String, double> sellerRevenue = {};
      Map<String, int> sellerOrderCount = {};

      for (var order in orders) {
        final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        final String? phone = order['customer_phone'];
        final String? sellerId = order['seller_id'];

        revenue += amount;
        if (phone != null && phone.isNotEmpty) uniquePhones.add(phone);
        
        if (sellerId != null) {
          sellerRevenue[sellerId] = (sellerRevenue[sellerId] ?? 0) + amount;
          sellerOrderCount[sellerId] = (sellerOrderCount[sellerId] ?? 0) + 1;
        }
      }

      _totalRevenue = revenue;
      _uniqueCustomers = uniquePhones.length;

      // 5. Build Seller List
      List<Map<String, dynamic>> result = [];
      for (var profile in profiles) {
        final uid = profile['id'];
        result.add({
          'seller_id': uid,
          'name': profile['full_name'] ?? 'Unknown',
          'role': profile['role'],
          'total_sales': sellerRevenue[uid] ?? 0.0,
          'order_count': sellerOrderCount[uid] ?? 0,
        });
      }
      
      // Sort by sales descending
      result.sort((a, b) => (b['total_sales'] as double).compareTo(a['total_sales']));

      if (mounted) {
        setState(() {
          _sellerStats = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống Kê Doanh Số & Khách Hàng')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Summary Grid
                   GridView.count(
                     crossAxisCount: 2,
                     crossAxisSpacing: 12,
                     mainAxisSpacing: 12,
                     childAspectRatio: 1.5,
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     children: [
                       _buildStatCard('Khách Hàng', '$_uniqueCustomers', Icons.people, Colors.blue),
                       _buildStatCard('Doanh Thu', NumberFormat.compact(locale: 'vi').format(_totalRevenue), Icons.attach_money, Colors.green),
                       _buildStatCard('Sản Phẩm Đã Bán', '$_productsSold', Icons.inventory_2, Colors.orange),
                       _buildStatCard('Dịch Vụ Đã Bán', '$_servicesSold', Icons.build, Colors.purple),
                     ],
                   ),
                   const Gap(24),
                   const Text('Doanh Số Theo Nhân Viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const Gap(12),
                   
                   // Seller List
                   ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sellerStats.length,
                      separatorBuilder: (c, i) => const Gap(8),
                      itemBuilder: (context, index) {
                        final item = _sellerStats[index];
                        return Card(
                          color: index == 0 && (item['total_sales'] as double) > 0 ? const Color(0xFF2C2C2C) : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: index == 0 ? Colors.amber : Colors.grey.shade700,
                              foregroundColor: index == 0 ? Colors.black : Colors.white,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item['order_count']} đơn hàng'),
                            trailing: Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item['total_sales']),
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SellerSalesDetailPage(
                                    sellerId: item['seller_id'],
                                    sellerName: item['name'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                   ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const Gap(8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const Gap(4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
