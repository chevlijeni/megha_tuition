require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const connectDB = require('./config/db');

const seedUser = async () => {
    try {
        // Connect to database
        await connectDB();

        // Check if user already exists
        const existingUser = await User.findOne({ username: 'megha' });
        if (existingUser) {
            console.log('Admin user already exists! You can log in with username: megha');
            process.exit(0);
        }

        // Hash the password securely
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('megha1994', salt);

        // Create the user in MongoDB Atlas
        await User.create({
            username: 'megha',
            password: hashedPassword,
            role: 'admin'
        });

        console.log('✅ Admin user created successfully!');
        console.log('👉 Username: megha');
        console.log('👉 Password: megha1994');
        process.exit(0);
    } catch (error) {
        console.error('Failed to create user:', error);
        process.exit(1);
    }
};

seedUser();
