const axios = require('axios');

/**
 * Service to handle WhatsApp notifications
 * Note: To send messages automatically from the backend, 
 * you need a WhatsApp Business API provider (like Twilio, UltraMsg, Wati, etc.)
 */
class WhatsAppService {
  static async sendFeeConfirmation({ parentName, mobileNumber, studentName, amount, month, year }) {
    console.log(`[WhatsApp Backend] Sending confirmation to ${mobileNumber}...`);
    
    // Format mobile for WhatsApp (ensure country code +91)
    let cleanNumber = mobileNumber.replace(/[^0-9]/g, '');
    if (cleanNumber.length === 10) {
      cleanNumber = '91' + cleanNumber;
    }

    const message = `Hi ${parentName}, fee of Rs. ${amount} for ${studentName} has been collected successfully for ${month} ${year}. Regards, Megha Tuition Classes.`;

    /**
     * EXAMPLE INTEGRATION (e.g., UltraMsg)
     * To use a real service, uncomment and configure below:
     */
    /*
    try {
      const response = await axios.post('https://api.ultramsg.com/INSTANCE_ID/messages/chat', {
        token: 'YOUR_TOKEN',
        to: cleanNumber,
        body: message
      });
      return response.data;
    } catch (error) {
      console.error('WhatsApp Backend Error:', error.message);
    }
    */

    return { success: true, message: 'Message logged (Configure API for live delivery)' };
  }
}

module.exports = WhatsAppService;
