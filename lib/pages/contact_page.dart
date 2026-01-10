import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông Tin Liên Hệ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business, size: 80, color: Color(0xFF03DAC6)),
                  ),
                  const Gap(24),
                  const Text('PM_Sale', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Gap(8),
                  Text('Công ty Phương Minh Việt Nam', style: TextStyle(fontSize: 18, color: Colors.grey.shade400)),
                ],
              ),
            ),
            const Gap(40),
            const Divider(),
            const Gap(24),
            const Text('Chuyên cung cấp giải pháp:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const Gap(16),
            _buildItem(Icons.app_settings_alt, 'Thiết kế APP, WEB application'),
            _buildItem(Icons.home, 'Thi công tư vấn smarthome'),
            _buildItem(Icons.wifi, 'Hạ tầng mạng hotel, resort, office'),
            _buildItem(Icons.camera_outdoor, 'Hạ tầng camera an ninh'),
            const Gap(40),
            const Divider(),
            const Gap(24),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrlString('tel:0941351347'),
                  icon: const Icon(Icons.phone),
                  label: const Text('Hotline: 0941.351.347', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    backgroundColor: const Color(0xFF03DAC6),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF03DAC6).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF03DAC6), size: 24),
          ),
          const Gap(16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4))),
        ],
      ),
    );
  }
}
