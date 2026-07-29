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

  static String getWhatsAppUrl({
    required String parentName,
    required String mobileNumber,
    required String studentName,
    required String amount,
    required String month,
    required String year,
  }) {
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

    return 'https://wa.me/$cleanNumber?text=$message';
  }

  static Future<void> sendWhatsAppMessage({
    required String parentName,
    required String mobileNumber,
    required String studentName,
    required String amount,
    required String month,
    required String year,
  }) async {
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

    final waUrl = getWhatsAppUrl(
      parentName: parentName,
      mobileNumber: mobileNumber,
      studentName: studentName,
      amount: amount,
      month: month,
      year: year,
    );

    try {
      await launchUrl(
        Uri.parse(waUrl),
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_top',
      );
    } catch (e) {
      final appScheme = 'whatsapp://send?phone=$cleanNumber&text=$message';
      try {
        await launchUrl(
          Uri.parse(appScheme), 
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_top',
        );
      } catch (e2) {
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

  static String getReminderMessage({
    required String parentName,
    required String studentName,
    required String amount,
    required String month,
    required String year,
  }) {
    return '*PENDING FEE REMINDER - MEGHA TUITION CLASSES*\n\n'
           'Hi *$parentName*,\n'
           'This is a gentle reminder that the tuition fee of *Rs. $amount* for *$studentName* for the month of *$month $year* is currently pending.\n\n'
           'Please clear it at your earliest convenience. If already paid, please ignore this message.\n\n'
           'Regards,\n*Megha Chevli*';
  }

  static Future<void> sendWhatsAppReminder({
    required String parentName,
    required String mobileNumber,
    required String studentName,
    required String amount,
    required String month,
    required String year,
  }) async {
    String cleanNumber = mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final message = Uri.encodeComponent(getReminderMessage(
      parentName: parentName,
      studentName: studentName,
      amount: amount,
      month: month,
      year: year,
    ));

    final waUrl = 'https://wa.me/$cleanNumber?text=$message';

    try {
      await launchUrl(
        Uri.parse(waUrl),
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_top',
      );
    } catch (e) {
      final appScheme = 'whatsapp://send?phone=$cleanNumber&text=$message';
      try {
        await launchUrl(
          Uri.parse(appScheme), 
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_top',
        );
      } catch (e2) {
        final apiFallback = 'https://api.whatsapp.com/send?phone=$cleanNumber&text=$message';
        await launchUrl(
          Uri.parse(apiFallback), 
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_top',
        );
      }
    }
  }
}
