import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gap/gap.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import '../utils/save_file_helper.dart';
import 'my_orders_page.dart';

class OrderSuccessPage extends StatefulWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _saveQrCode() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        final fileName = 'QR_Order_${widget.orderId}.png';
        await saveFile(pngBytes, fileName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã lưu QR code: $fileName')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Hàng Thành Công'),
        automaticallyImplyLeading: false, 
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const Gap(24),
              const Text(
                'Cảm ơn bạn đã mua hàng!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                'Mã đơn hàng: #${widget.orderId}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Gap(32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Mã QR Bảo Hành', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Gap(8),
                    RepaintBoundary(
                      key: _qrKey,
                       child: Container(
                        color: Colors.white, // Ensure white background for transparent png
                        padding: const EdgeInsets.all(10),
                        child: QrImageView(
                          data: widget.orderId,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const Gap(8),
                    const Text(
                      'Vui lòng lưu lại mã QR hoặc Mã đơn hàng để tra cứu bảo hành sau này.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(16),
                    ElevatedButton.icon(
                      onPressed: _saveQrCode,
                      icon: const Icon(Icons.download),
                      label: const Text('Lưu Mã QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Về Trang Chủ'),
              ),
              const Gap(16),
              TextButton(
                onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                    );
                },
                child: const Text('Xem Trạng Thái Đơn Hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
