import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  
  bool _isLoading = true;
  String? _avatarUrl;
  String? _role;
  String? _phone;
  
  // Chart Data
  Map<int, double> _monthlySales = {};
  double _totalYearSales = 0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSalesData();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      setState(() {
        _nameController.text = data['full_name'] ?? '';
        _avatarUrl = data['avatar_url'];
        _role = data['role'];
        _phone = data['phone_number'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải hồ sơ: $e')));
    }
  }

  Future<void> _loadSalesData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final now = DateTime.now();
      
      // Fetch orders for this seller for the entire YEAR
      final startOfYear = DateTime(now.year, 1, 1).toIso8601String();
      
      final response = await Supabase.instance.client
          .from('orders')
          .select('total_amount, created_at')
          .eq('seller_id', userId)
          .gte('created_at', startOfYear)
          .order('created_at', ascending: true);
      
      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) return;

      Map<int, double> salesByMonth = {};
      double total = 0;

      for (var item in data) {
        final date = DateTime.parse(item['created_at']).toLocal();
        final month = date.month;
        final amount = (item['total_amount'] as num).toDouble();
        salesByMonth[month] = (salesByMonth[month] ?? 0) + amount;
        total += amount;
      }

      setState(() {
        _monthlySales = salesByMonth;
        _totalYearSales = total;
      });

    } catch (e) {
      debugPrint('Chart Error: $e');
    }
  }

  Future<void> _updateAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileExt = image.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, File(image.path));
      
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      setState(() {
        _avatarUrl = imageUrl;
        _isLoading = false;
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật avatar thành công!')));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    // Using a ValueNotifier to manage state within the dialog without creating a separate StatefulWidget class
    // actually, StatefulBuilder is better for Dialogs
    
    showDialog(
      context: context,
      builder: (context) {
        bool obscurePassword = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Đổi Mật Khẩu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const Gap(16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                     final pass = passwordController.text;
                     final confirm = confirmPasswordController.text;

                     if (pass.length < 6) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu phải > 6 ký tự')));
                       return;
                     }
                     
                     if (pass != confirm) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu xác nhận không khớp')));
                       return;
                     }

                     Navigator.pop(context); // Close dialog first

                     try {
                       await Supabase.instance.client.auth.updateUser(
                         UserAttributes(password: pass.trim())
                       );
                       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
                     } catch (e) {
                       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                     }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format currency
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Cá Nhân'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            icon: const Icon(Icons.home),
            tooltip: 'Về trang chủ',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar Section
                GestureDetector(
                  onTap: _updateAvatar,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF10B981), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                Text(_nameController.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_role?.toUpperCase() ?? 'MEMBER', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const Gap(4),
                Text(_phone ?? '', style: TextStyle(color: Colors.grey.shade600)),
                
                const Gap(24),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     ElevatedButton(
                      onPressed: _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Row(children: [Icon(Icons.lock_reset, size: 18), Gap(8), Text('Đổi Mật Khẩu')]),
                    ),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: () => Supabase.instance.client.auth.signOut().then((_) => Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                       child: const Row(children: [Icon(Icons.logout, size: 18), Gap(8), Text('Đăng Xuất')]),
                    ),
                  ],
                ),

                const Gap(32),

                // Sales Chart Section (Only for Sales/Admin)
                if (_role == 'sales' || _role == 'admin') ...[
                  Align(alignment: Alignment.centerLeft, child: Text('Doanh Số Năm Nay (Theo Tháng)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18))),
                  const Gap(8),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Tổng: ${currencyFormat.format(_totalYearSales)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                          const Gap(24),
                          SizedBox(
                            height: 300,
                            child: _monthlySales.isEmpty
                                ? const Center(child: Text('Chưa có dữ liệu bán hàng năm nay', style: TextStyle(color: Colors.grey)))
                                : BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: _monthlySales.values.reduce((curr, next) => curr > next ? curr : next) * 1.2,
                                      barTouchData: BarTouchData(
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (_) => Colors.blueGrey,
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            return BarTooltipItem(
                                              'T${group.x}\n',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: NumberFormat.compact(locale: 'vi').format(rod.toY),
                                                  style: const TextStyle(
                                                    color: Colors.yellow,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (double value, TitleMeta meta) {
                                              return Text(
                                                'T${value.toInt()}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                               if (value == 0) return const SizedBox.shrink();
                                               return Text(
                                                 NumberFormat.compact(locale: 'vi').format(value),
                                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                               );
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      gridData: const FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: List.generate(12, (index) {
                                        final month = index + 1;
                                        final value = _monthlySales[month] ?? 0;
                                        return BarChartGroupData(
                                          x: month,
                                          barRods: [
                                            BarChartRodData(
                                              toY: value,
                                              color: const Color(0xFF10B981),
                                              width: 16,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                              backDrawRodData: BackgroundBarChartRodData(
                                                show: true,
                                                toY: _monthlySales.values.isEmpty ? 0 : _monthlySales.values.reduce((curr, next) => curr > next ? curr : next) * 1.2,
                                                color: Colors.grey.withOpacity(0.1),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }
}
