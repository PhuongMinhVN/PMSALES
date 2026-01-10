import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rzygcjxrxwblhbstvfvk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6eWdjanhyeHdibGhic3R2ZnZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0ODk0MTAsImV4cCI6MjA4MzA2NTQxMH0.269gTcCqMEPsem3zQrvbU6Pni0TBjGuMM1DwGzfqf_I',
  );

  runApp(const SetupApp());
}

class SetupApp extends StatelessWidget {
  const SetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SetupPage(),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String _status = 'Ready to create Admin User...';
  bool _isLoading = false;

  Future<void> _createAdmin() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating user...';
    });

    try {
      final username = 'trungct'; 
      final email = '$username@pm.app'; 
      final password = '123456';

      // 1. Sign Up
      AuthResponse res;
      try {
        res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        _status = 'Sign up successful (or user exists).';
      } catch (e) {
        _status = 'Sign up note: $e';
        // Try signing in
        res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      if (res.user == null) {
         if (res.session == null) {
            throw Exception('User created but email not confirmed. Since you disabled "Confirm Email" in Supabase, this might be an old user. Try a different username or delete this user in Supabase.');
         }
         throw Exception('Failed to get user session.');
      }
      
      final userId = res.user!.id;
      _status = 'User ID: $userId. Creating Profile...';

      // 2. Insert/Update Profile
      final profileCheck = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileCheck == null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': userId,
          'phone_number': username,
          'full_name': 'TrungCT Admin',
          'role': 'admin',
        });
        _status = 'Profile created! Success.';
      } else {
        await Supabase.instance.client.from('profiles').update({
          'role': 'admin',
          'phone_number': username,
        }).eq('id', userId);
        _status = 'Profile updated to Admin (trungct / 123456)! Success.';
      }

      setState(() {
        _status += '\n\nLOGIN DETAILS:\nUser: $username\nPassword: $password';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Setup')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _createAdmin,
                  child: const Text('Create Admin (trungct / 123456)'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
