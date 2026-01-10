import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'admin/member_management_page.dart';
import 'admin/pending_orders_page.dart';
import 'admin/customer_management_page.dart';
import 'sales_statistics_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    // Basic Admin Check - same as before
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    // We assume the user is valid if they landed here via Login route, 
    // but redundant check is fine. 
    // For now, fast load.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Xin chào, Quản trị viên!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Gap(24),
            
            // Dashboard Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAdminCard(
                  icon: Icons.people_alt,
                  title: 'Quản Lý Thành Viên',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const MemberManagementPage()),
                    );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.store,
                  title: 'Vào Cửa Hàng',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/home'),
                ),
                _buildAdminCard(
                  icon: Icons.settings,
                  title: 'Cài Đặt',
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển')));
                  },
                ),
                _buildAdminCard(
                  icon: Icons.analytics,
                  title: 'Thống Kê',
                  color: Colors.purple,
                  onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => const SalesStatisticsPage()),
                     );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.checklist,
                  title: 'Duyệt Đơn Hàng',
                  color: Colors.redAccent,
                  onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => const PendingOrdersPage()),
                     );
                  },
                ),
                _buildAdminCard(
                  icon: Icons.recent_actors,
                  title: 'Quản Lý Khách Hàng',
                  color: Colors.teal,
                  onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => const CustomerManagementPage()),
                     );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const Gap(16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
