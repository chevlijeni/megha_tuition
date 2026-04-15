const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
            family: 4
        });
        console.log(`MongoDB Atlas Connected: ${conn.connection.host}`);
        return conn;
    } catch (err) {
        console.error(`MongoDB Atlas Connection Error: ${err.message}`);
        throw err; // Re-throw to handle it in app.js
    }
};

module.exports = connectDB;
