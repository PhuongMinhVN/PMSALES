import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
           for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
               controller.stop();
               Navigator.pop(context, barcode.rawValue);
               break; 
            }
          }
        },
      ),
    );
  }
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
