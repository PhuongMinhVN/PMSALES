import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for a bit
    
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
       // Check role
       try {
         final profile = await Supabase.instance.client
             .from('profiles')
             .select()
             .eq('id', session.user.id)
             .maybeSingle();
         
         if (mounted) {
           final status = profile?['status'] as String? ?? 'active';
           if (status != 'active') {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
              return;
           }

           if (profile != null && profile['role'] == 'admin') {
             Navigator.pushReplacementNamed(context, '/admin');
           } else {
             Navigator.pushReplacementNamed(context, '/home');
           }
         }
       } catch (e) {
         // If error checking profile, go to home as safe default
         if (mounted) Navigator.pushReplacementNamed(context, '/home');
       }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark tech blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon with techy effects
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ).then().scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1, 1),
                  duration: 2.seconds,
                   curve: Curves.easeInOut,
                ),
                const Icon(Icons.storefront, size: 60, color: Color(0xFF10B981))
                    .animate().fadeIn(duration: 1.seconds).scale(),
              ],
            ),
            const Gap(40),
            // Text with typing effect
            const Text(
              'PMVN SYSTEM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'Courier', 
              ),
            ).animate().fadeIn(duration: 2.seconds).slide(begin: const Offset(0, 0.2)),
            
            const Gap(16),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFF1E293B),
                color: Color(0xFF10B981),
              ),
            ).animate().fadeIn(delay: 1.seconds),
            
            const Gap(8),
            const Text(
              'Initializing...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ).animate().fadeIn(delay: 1.5.seconds),
          ],
        ),
      ),
    );
  }
}
