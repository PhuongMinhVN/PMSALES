import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  static Future<void> generateAndPrint({
    required String orderId,
    required DateTime date,
    required String sellerName,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    double discountPercent = 0,
  }) async {
    final doc = pw.Document();
    
    // Load font for Vietnamese support
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - Stacked for Mobile/A5
              pw.Center(
                child: pw.Column(
                  children: [
                     pw.Text('PMVN Tech & More', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.teal)),
                     pw.Text('Địa chỉ: 5/5 Phan Đình Phùng, Trung Sơn, Ninh Bình', style: pw.TextStyle(font: font, fontSize: 9)),
                     pw.SizedBox(height: 5),
                     pw.Text('HOÁ ĐƠN BÁN HÀNG', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                     pw.Text('KIÊM BẢO HÀNH', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Info Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Expanded(
                     child: pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                         _buildText('Nhân viên sale: $sellerName', font),
                         _buildText('Ngày giờ: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}', font),
                         pw.SizedBox(height: 5),
                         _buildText('Khách hàng: $customerName', fontBold),
                         _buildText('SĐT: $customerPhone', font),
                         _buildText('Địa chỉ: $customerAddress', font),
                       ],
                     ),
                   ),
                   // QR Code
                   pw.Container(
                     height: 60,
                     width: 60,
                     child: pw.BarcodeWidget(
                       barcode: pw.Barcode.qrCode(),
                       data: orderId,
                     ),
                   ),
                ],
              ),
              pw.SizedBox(height: 15),

              // Items Table
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                headerHeight: 20,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // Name
                  1: const pw.FlexColumnWidth(1.2), // Warranty
                  2: const pw.FixedColumnWidth(20), // Qty
                  3: const pw.FlexColumnWidth(1.5), // Price
                  4: const pw.FlexColumnWidth(1.5), // Total
                },
                headers: <String>['Sản Phẩm', 'BH', 'SL', 'Đơn Giá', 'T.Tiền'],
                data: items.map((item) {
                  return [
                    item['name'],
                    item['warranty'],
                    item['quantity'].toString(),
                    _formatCurrency(item['price']),
                    _formatCurrency(item['total']),
                  ];
                }).toList(),
              ),
              pw.Divider(),

              // Total
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                     if (discountPercent > 0) ...[
                        pw.Text('Tạm tính: ${_formatCurrency(items.fold(0, (sum, item) => sum + (item['total'] as double)))}', style: pw.TextStyle(font: font, fontSize: 11)),
                        pw.Text('Giảm giá: $discountPercent%', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.red)),
                        pw.Divider(), 
                     ],
                    pw.Text('Tổng cộng: ${_formatCurrency(totalAmount)}', style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.red)),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Center(
                child: pw.Text('Cảm ơn quý khách đã mua hàng tại PMVN Tech & More!', style: pw.TextStyle(font: font, fontStyle: pw.FontStyle.italic, fontSize: 9)),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text('Hotline: 0941.351.347 - Email: phuongminhvietnam@gmail.com', style: pw.TextStyle(font: fontBold, fontSize: 8)),
              ),
               pw.SizedBox(height: 5),
               pw.Center(
                child: pw.Text('Mã hoá đơn: $orderId', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    String productList = items.map((e) => e['name'].toString()).join(', ');
    if (productList.length > 60) productList = '${productList.substring(0, 60)}...';
    
    // Sanitize slightly for filename safety if needed, but usually modern browsers handle it.
    final fileName = '$customerName - $productList.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: fileName,
    );
  }

  static pw.Widget _buildText(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 12)),
    );
  }

  static String _formatCurrency(double amount) {
    // Basic format, as intl NumberFormat might need locale data loaded in pure dart environment differently,
    // but flutter intl works.
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(amount);
  }
}
