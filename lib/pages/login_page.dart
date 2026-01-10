import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _phoneController.text = prefs.getString('saved_phone') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final email = '$phone@pm.app';

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('saved_phone', phone);
          await prefs.setString('saved_password', password);
        } else {
          await prefs.remove('remember_me');
          await prefs.remove('saved_phone');
          await prefs.remove('saved_password');
        }

        // Fetch User Profile to get Role
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
        
        if (mounted) {
           if (profileData == null) {
              // Fallback if no profile exists
              Navigator.pushReplacementNamed(context, '/home');
           } else {
             final role = profileData['role'] as String?;
             final status = profileData['status'] as String? ?? 'active';

             if (status != 'active') {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ Admin.'),
                       backgroundColor: Colors.red,
                       duration: Duration(seconds: 5),
                     ),
                   );
                   setState(() => _isLoading = false);
                }
                return;
             }

             if (role == 'admin') {
               Navigator.pushReplacementNamed(context, '/admin');
             } else {
               Navigator.pushReplacementNamed(context, '/home');
             }
           }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = e.message;
        if (message.contains('Email not confirmed')) {
          message = 'Lỗi: Email chưa được xác nhận.\nVui lòng vào Supabase Dashboard -> Authentication -> Providers -> Email -> Tắt "Confirm email".';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront, size: 80, color: const Color(0xFF10B981)),
                  const Gap(16),
                  const Text(
                    'Quản Lý Bán Hàng',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Gap(32),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.text, 
                    decoration: const InputDecoration(
                      labelText: 'Tài khoản (admin / SĐT)',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const Gap(16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Lưu thông tin đăng nhập'),
                    ],
                  ),
                  const Gap(24),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        print('Navigating to Warranty Lookup...');
                        Navigator.pushNamed(context, '/lookup_warranty');
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Tra Cứu Bảo Hành'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF03DAC6)),
                        foregroundColor: const Color(0xFF03DAC6),
                      ),
                    ),
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Đăng Nhập', style: TextStyle(fontSize: 16)),
                  ),
                  const Gap(48),
                  const Column(
                    children: [
                      Text(
                        'Powered by PMVN',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      Gap(4),
                      Text(
                        'email : phuongminhvietnam@gmail.com',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
