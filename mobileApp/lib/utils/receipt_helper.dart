import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ReceiptHelper {
  static Future<void> generateAndShareReceipt({
    required String studentName,
    required String studentId,
    required String amount,
    required String month,
    required String year,
    required String paymentMode,
    required String parentName,
    required String mobileNumber,
  }) async {
    final pdf = pw.Document();

    // Load logo if exists
    Uint8List? logoBytes;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (e) {
      print('Logo not found: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MEGHA TUITION CLASSES',
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Quality Education for Better Future',
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    if (logoBytes != null)
                      pw.Image(pw.MemoryImage(logoBytes), width: 50),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('FEE RECEIPT',
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline)),
                ),
                pw.SizedBox(height: 20),
                
                // Receipt Details
                _buildReceiptRow('Receipt Date:', DateFormat('dd MMM yyyy').format(DateTime.now())),
                _buildReceiptRow('Student Name:', studentName.toUpperCase()),
                _buildReceiptRow('Student ID:', studentId),
                _buildReceiptRow('Parent Name:', parentName),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey100, thickness: 1),
                pw.SizedBox(height: 10),
                _buildReceiptRow('Fees for Month:', '$month $year'),
                _buildReceiptRow('Payment Mode:', paymentMode),
                _buildReceiptRow('Amount Paid:', 'Rs. $amount', isBold: true),
                
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Status: PAID', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Note: Computer generated receipt.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 80, height: 1, color: PdfColors.black),
                        pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Provide printing/downloading option
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${studentName}_$month.pdf',
    );
  }

  static pw.Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700))),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> sendWhatsAppMessage({
    required String parentName,
    required String mobileNumber,
    required String studentName,
    required String amount,
    required String month,
    required String year,
  }) async {
    // Format mobile number: remove spaces and ensure country code (assume India +91 if 10 digits)
    String cleanNumber = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final message = Uri.encodeComponent(
      'Hi $parentName, fee of Rs. $amount for $studentName has been collected successfully for $month $year. Regards, Megha Tuition Classes.'
    );

    final url = 'https://wa.me/$cleanNumber?text=$message';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}
