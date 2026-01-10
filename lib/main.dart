import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/add_product_page.dart';
import 'pages/warranty_page.dart';
import 'pages/admin_page.dart';
import 'pages/splash_page.dart';
import 'pages/contact_page.dart';
import 'pages/sales_statistics_page.dart';
import 'pages/profile_page.dart';
import 'pages/customer_warranty_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://rzygcjxrxwblhbstvfvk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6eWdjanhyeHdibGhic3R2ZnZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0ODk0MTAsImV4cCI6MjA4MzA2NTQxMH0.269gTcCqMEPsem3zQrvbU6Pni0TBjGuMM1DwGzfqf_I',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'PM App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212), // Deep Dark
          cardColor: const Color(0xFF1E1E1E), // Dark Card
          canvasColor: const Color(0xFF121212), // For Drawer
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF03DAC6), // Teal Accent (Luxury)
            secondary: const Color(0xFFBB86FC),
            surface: const Color(0xFF1E1E1E),
            background: const Color(0xFF121212),
            onPrimary: Colors.black, // Text on Teal buttons
            onSurface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Color(0xFF03DAC6), // Teal Icons/Text
            elevation: 0,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFF2C2C2C), // Dark Grey Inputs
            hintStyle: const TextStyle(color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03DAC6),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF03DAC6),
            foregroundColor: Colors.black,
          ),
        ),
        initialRoute: '/splash', 
        routes: {
          '/splash': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(), 
          '/add_product': (context) => const AddProductPage(),
          '/warranty': (context) => const WarrantyPage(),
          '/admin': (context) => const AdminPage(),
          '/profile': (context) => const ProfilePage(),
          '/contact': (context) => const ContactPage(),
          '/sales_stats': (context) => const SalesStatisticsPage(),
          '/lookup_warranty': (context) => const CustomerWarrantyPage(),
        },
      ),
    );
  }
}
