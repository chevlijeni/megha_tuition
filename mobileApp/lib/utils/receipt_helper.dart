import 'package:url_launcher/url_launcher.dart';

class ReceiptHelper {
  /**
   * Service to trigger automated WhatsApp messages via frontend fallback
   * NOTE: Backend automated WhatsApp is already active in studentController.js
   */
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
      '*MEGHA TUITION CLASSES*\n\n'
      'Hi *$parentName*, fee of *Rs. $amount* for *$studentName* has been collected successfully for *$month $year*.\n\n'
      'Regards,\n*Megha Tuition Classes*'
    );

    // Using api.whatsapp.com for better universal linking across mobile browsers and PWAs
    final url = 'https://api.whatsapp.com/send?phone=$cleanNumber&text=$message';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Fallback
      final fallbackUrl = 'https://wa.me/$cleanNumber?text=$message';
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.platformDefault);
    }
  }
}
