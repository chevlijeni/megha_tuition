const axios = require('axios');

/**
 * Service to handle WhatsApp notifications via UltraMsg
 */
class WhatsAppService {
  static async sendFeeConfirmation({ parentName, mobileNumber, studentName, amount, month, year }) {
    const instanceId = process.env.ULTRAMSG_INSTANCE_ID || 'instance171629';
    const token = process.env.ULTRAMSG_TOKEN || 'z5kmg8e3ft1pnqxa';

    if (!instanceId || !token) {
      console.warn('[WhatsApp] Credentials missing in .env. Skipping notification.');
      return;
    }

    console.log(`[WhatsApp] Sending confirmation to ${mobileNumber} via UltraMsg...`);
    
    // Format mobile for WhatsApp (ensure country code and + prefix)
    let cleanNumber = mobileNumber.replace(/[^0-9]/g, '');
    if (cleanNumber.length === 10) {
      cleanNumber = '91' + cleanNumber;
    }
    
    // UltraMsg/WhatsApp APIs usually work best with the + prefix
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+' + cleanNumber;
    }

    console.log(`[WhatsApp] 🚀 Attempting to send to: ${cleanNumber}`);
    
    const message = `Hi ${parentName}, fee of Rs. ${amount} for ${studentName} has been collected successfully for ${month} ${year}. Regards, Megha Tuition Classes.`;

    try {
      const response = await axios.post(`https://api.ultramsg.com/${instanceId}/messages/chat`, {
        token: token,
        to: cleanNumber,
        body: message,
        priority: 10
      });

      console.log(`[WhatsApp] ✅ Response Received:`, JSON.stringify(response.data));

      if (response.data && (response.data.sent === 'true' || response.data.sent === true)) {
        console.log(`[WhatsApp] 📬 Message sent successfully (ID: ${response.data.id})`);
      } else {
        console.warn('[WhatsApp] ⚠️ API accepted message but return status not "sent":', response.data);
      }
      
      return response.data;
    } catch (error) {
      console.error('[WhatsApp] ❌ API Error:', error.response ? JSON.stringify(error.response.data) : error.message);
      throw error;
    }
  }
}

module.exports = WhatsAppService;
