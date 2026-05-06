import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptHelper {
  /**
   * Service to trigger automated WhatsApp messages via frontend fallback
   * NOTE: Backend automated WhatsApp is already active in studentController.js
   */
  static String getReceiptMessage({
    required String parentName,
    required String studentName,
    required String amount,
    required String month,
    required String year,
  }) {
    return '*MEGHA TUITION CLASSES*\n\n'
           'Hi *$parentName*, fee of *Rs. $amount* for *$studentName* has been collected successfully for *$month $year*.\n\n'
           'Regards,\n*Megha Chevli*';
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

    final message = Uri.encodeComponent(getReceiptMessage(
      parentName: parentName,
      studentName: studentName,
      amount: amount,
      month: month,
      year: year,
    ));

    // Simplified for maximum iOS compatibility
    final waUrl = 'https://wa.me/$cleanNumber?text=$message';

    try {
      // webOnlyWindowName: '_top' is critical for iOS Chrome and PWA to bypass popup blockers
      await launchUrl(
        Uri.parse(waUrl),
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_top',
      );
    } catch (e) {
      // If that fails, try the absolute direct app scheme
      final appScheme = 'whatsapp://send?phone=$cleanNumber&text=$message';
      try {
        await launchUrl(
          Uri.parse(appScheme), 
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_top',
        );
      } catch (e2) {
        // Final fallback to api link
        final apiFallback = 'https://api.whatsapp.com/send?phone=$cleanNumber&text=$message';
        await launchUrl(
          Uri.parse(apiFallback), 
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_top',
        );
      }
    }
  }

  static Future<void> shareReceipt({
    required String parentName,
    required String studentName,
    required String amount,
    required String month,
    required String year,
  }) async {
    final message = getReceiptMessage(
      parentName: parentName,
      studentName: studentName,
      amount: amount,
      month: month,
      year: year,
    );
    
    await Share.share(message);
  }
}
