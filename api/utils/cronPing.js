const cron = require('node-cron');
const https = require('https');

const SERVER_URL = 'https://megha-tuition.onrender.com/api/v1/ping';

const startCronPing = () => {
    // Run every 12 minutes (Render sleeps after 15 minutes of inactivity)
    cron.schedule('*/12 * * * *', () => {
        console.log(`[CRON] Pinging server at ${SERVER_URL} to prevent sleep...`);
        
        https.get(SERVER_URL, (res) => {
            if (res.statusCode === 200) {
                console.log('[CRON] Ping successful! Server is awake.');
            } else {
                console.log(`[CRON] Ping received unexpected status code: ${res.statusCode}`);
            }
        }).on('error', (err) => {
            console.error('[CRON] Error during ping:', err.message);
        });
    });
};

module.exports = startCronPing;
