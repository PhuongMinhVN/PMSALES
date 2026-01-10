import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final res = await Supabase.instance.client
          .from('orders')
          .select('customer_name, customer_phone, customer_address, google_maps_link, created_at')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> distinctCustomers = [];
      final seenPhones = <String>{};

      for (var order in res) {
        final phone = order['customer_phone'] as String?;
        final name = order['customer_name'] as String?;
        
        // Key for deduplication: Phone is primary, Name is fallback
        final key = (phone != null && phone.isNotEmpty) ? phone : name;

        if (key != null && key.isNotEmpty && !seenPhones.contains(key)) {
          seenPhones.add(key);
          distinctCustomers.add(order);
        }
      }

      if (mounted) {
        setState(() {
          _customers = distinctCustomers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách khách hàng: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Khách Hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Tên Khách Hàng')),
                    DataColumn(label: Text('SĐT')),
                    DataColumn(label: Text('Địa Chỉ')),
                    DataColumn(label: Text('Google Maps')),
                  ],
                  rows: _customers.map((customer) {
                    final mapLink = customer['google_maps_link'] as String?;
                    return DataRow(cells: [
                      DataCell(Text(customer['customer_name'] ?? '---')),
                      DataCell(Text(customer['customer_phone'] ?? '---')),
                      DataCell(Text(customer['customer_address'] ?? '---')),
                      DataCell(
                        mapLink != null && mapLink.isNotEmpty
                            ? InkWell(
                                onTap: () => launchUrlString(mapLink),
                                child: const Row(
                                  children: [
                                    Icon(Icons.map, color: Colors.blue, size: 16),
                                    SizedBox(width: 4),
                                    Text('Mở Map', style: TextStyle(color: Colors.blue)),
                                  ],
                                ),
                              )
                            : const Text('---', style: TextStyle(color: Colors.grey)),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
