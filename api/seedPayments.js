require('dotenv').config();
const mongoose = require('mongoose');
const Student = require('./models/Student');
const Payment = require('./models/Payment');
const connectDB = require('./config/db');

const seedPayments = async () => {
    try {
        await connectDB();

        // Clear existing payments for a fresh start
        await Payment.deleteMany({});
        console.log('🗑️ Existing payments cleared.');

        const students = await Student.find({ status: 'Active' });
        if (students.length === 0) {
            console.log('❌ No active students found. Add some students first!');
            process.exit(0);
        }

        const now = new Date();
        const currentMonth = now.getMonth() + 1;
        const currentYear = now.getFullYear();

        // Seed payments for half of the students
        const half = Math.ceil(students.length / 2);
        const payingStudents = students.slice(0, half);

        const paymentRecords = payingStudents.map(student => ({
            student: student._id,
            amount: student.feeDetails.feeAmount,
            month: currentMonth,
            year: currentYear,
            paymentMethod: 'Cash',
            receiptNumber: `RCPT-${Math.floor(Math.random() * 1000000)}`
        }));

        await Payment.insertMany(paymentRecords);
        console.log(`✅ Successfully seeded ${payingStudents.length} payments for ${now.toLocaleString('default', { month: 'long' })} ${currentYear}`);
        
        process.exit(0);
    } catch (error) {
        console.error('Failed to seed payments:', error);
        process.exit(1);
    }
};

seedPayments();
