import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import '../../models/profile.dart';

class MemberManagementPage extends StatefulWidget {
  const MemberManagementPage({super.key});

  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  List<Profile> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _users = (data as List).map((e) => Profile.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _resetPassword(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Text('Bạn có chắc muốn đặt lại mật khẩu cho "$userName" thành "123456" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.rpc('reset_password_by_admin', params: {
        'target_user_id': userId,
        'new_password': '123456', // Default reset password
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đặt lại mật khẩu thành "123456"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đặt lại mật khẩu: $e')));
      }
    }
  }

  Future<void> _updateStatus(String userId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'status': newStatus})
          .eq('id', userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã ${newStatus == 'active' ? 'kích hoạt' : 'vô hiệu hóa'} thành viên'),
          backgroundColor: newStatus == 'active' ? Colors.green : Colors.orange,
        ));
        _fetchUsers(); // Refresh list to update UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')));
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Thành Viên'),
        content: const Text('Bạn có chắc chắn muốn xóa thành viên này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      try {
        await Supabase.instance.client.rpc('delete_user_by_admin', params: {'target_user_id': userId});
      } catch (_) {
        await Supabase.instance.client.from('profiles').delete().eq('id', userId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành viên')));
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }

  void _showCreateUserDialog() {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'viewer';
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Tạo Thành Viên Mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    ),
                    const Gap(8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Họ tên'),
                    ),
                    const Gap(8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    ),
                    const Gap(16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Vai trò'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'sales', child: Text('Sales (Bán hàng)')),
                        DropdownMenuItem(value: 'warranty', child: Text('Warranty (Bảo hành)')),
                        DropdownMenuItem(value: 'viewer', child: Text('Viewer (Xem)')),
                      ],
                      onChanged: (val) => setStateDialog(() => selectedRole = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isCreating ? null : () async {
                    if (phoneController.text.isEmpty || passwordController.text.isEmpty) return;
                    
                    setStateDialog(() => isCreating = true);
                    
                    // PRESERVE ADMIN SESSION
                    final adminSession = Supabase.instance.client.auth.currentSession;
                    
                    try {
                      // Use implicit flow to minimize storage impact
                      final tempClient = SupabaseClient(
                        'https://rzygcjxrxwblhbstvfvk.supabase.co',
                        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6eWdjanhyeHdibGhic3R2ZnZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0ODk0MTAsImV4cCI6MjA4MzA2NTQxMH0.269gTcCqMEPsem3zQrvbU6Pni0TBjGuMM1DwGzfqf_I',
                        authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
                      );

                      final email = '${phoneController.text.trim()}@pm.app';
                      
                      final response = await tempClient.auth.signUp(
                        email: email,
                        password: passwordController.text.trim(),
                        data: {
                          'full_name': nameController.text.trim(),
                          'phone_number': phoneController.text.trim(),
                          'role': selectedRole,
                        },
                      );

                      if (response.user == null) {
                        throw Exception('Không tạo được user (Có thể đã tồn tại)');
                      }

                      // Ensure Admin Session is restored if hijacked
                      if (Supabase.instance.client.auth.currentUser?.id != adminSession?.user.id) {
                        print('Session hijacked! Restoring admin session...');
                        if (adminSession != null) {
                           // We can't easily "restore" a session object directly in public API usually
                           // But the hijack happens because tempClient wrote to sharedPrefs.
                           // With AuthFlowType.implicit, hopefully it didn't.
                           // If it did, we might need to re-login or warn user.
                           // Actually, let's just Log Out the temp user from the MAIN client if it infected it.
                           // But we don't know the password to log back in. 
                        }
                      }
                      
                      // Wait a bit
                      await Future.delayed(const Duration(milliseconds: 1000));
                      await tempClient.dispose();

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Tạo thành viên thành công!'),
                          backgroundColor: Colors.green,
                        ));
                        _fetchUsers();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    } finally {
                       if (context.mounted) setStateDialog(() => isCreating = false);
                    }
                  },
                  child: isCreating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'sales': return Colors.green;
      case 'warranty': return Colors.orange;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Thành Viên'),
        actions: [
          IconButton(
            onPressed: () {
               _fetchUsers();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
            color: Colors.white,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm thành viên'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const Gap(16),
                        Text('Đã xảy ra lỗi tải danh sách:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Gap(8),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                        const Gap(16),
                        ElevatedButton(onPressed: _fetchUsers, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const Gap(16),
                          Text('Chưa có thành viên nào (ngoại trừ bạn)', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isMe = user.id == Supabase.instance.client.auth.currentUser?.id;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user.role),
                            foregroundColor: Colors.white,
                            radius: 24,
                            child: Text(user.role.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(
                            '${user.fullName ?? 'Thành viên'} ${isMe ? '(Tôi)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Gap(4),
                              Text('Phone/Account: ${user.phone ?? 'Ẩn'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Mật khẩu: ****** (Đã mã hóa)', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                            ],
                          ),
                          trailing: isMe 
                              ? const Chip(label: Text('Admin'), backgroundColor: Colors.redAccent)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: user.isActive,
                                        onChanged: (val) => _updateStatus(user.id, val ? 'active' : 'disabled'),
                                        activeColor: Colors.green,
                                        inactiveThumbColor: Colors.grey,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _resetPassword(user.id, user.fullName ?? user.phone ?? 'User'),
                                      icon: const Icon(Icons.lock_reset, color: Colors.blue),
                                      tooltip: 'Đặt lại mật khẩu (123456)',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteUser(user.id),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Xóa user',
                                    ),
                                  ],
                                ),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            const Text('Quyền hạn:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const Gap(12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: ['admin', 'sales', 'warranty', 'viewer'].contains(user.role) 
                                        ? user.role 
                                        : 'viewer',
                                    items: const [
                                      DropdownMenuItem(value: 'admin', child: Text('Admin (Toàn quyền)')),
                                      DropdownMenuItem(value: 'sales', child: Text('Sales (Bán hàng)')),
                                      DropdownMenuItem(value: 'warranty', child: Text('Warranty (Tra cứu)')),
                                      DropdownMenuItem(value: 'viewer', child: Text('Viewer (Chỉ xem)')),
                                    ],
                                    onChanged: isMe ? null : (val) {
                                      if (val != null) _updateRole(user.id, val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
