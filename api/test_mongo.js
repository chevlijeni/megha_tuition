const mongoose = require('mongoose');

async function testConnection() {
    console.log("Attempting to connect to Atlas...");
    mongoose.set('debug', true);

    try {
        const uri = "mongodb+srv://chevlijeny1992_db_user:LAHzesytlZYTOyH4@cluster0.rmwf2d9.mongodb.net/tuition_fees?appName=Cluster0";
        await mongoose.connect(uri, {
            serverSelectionTimeoutMS: 5000,
            family: 4 // Force IPv4 to bypass Node 18+ networking bugs
        });
        console.log("SUCCESS!");
        process.exit(0);
    } catch (error) {
        console.error("FAILED TO CONNECT:");
        console.error(error);
        process.exit(1);
    }
}

testConnection();
