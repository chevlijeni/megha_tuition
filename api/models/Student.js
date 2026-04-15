const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
    studentId: {
        type: String,
        required: true,
        unique: true
    },
    personalDetails: {
        fullName: { type: String, required: true },
        dob: { type: Date },
        gender: { type: String, enum: ['Male', 'Female', 'Other'], required: true }
    },
    academicDetails: {
        className: { type: String, required: true },
        board: { type: String, enum: ['GSEB', 'CBSC'], required: true },
        batchTime: { type: String, enum: ['Morning', 'Afternoon', 'Evening'], required: true },
        schoolName: { type: String },
        enrollmentDate: { type: Date, required: true }
    },
    feeDetails: {
        feeAmount: { type: Number, required: true },
        dueDayOfMonth: { type: Number, required: true, min: 1, max: 31 },
        billCycle: { type: String, enum: ['Monthly', 'Quarterly', 'Yearly'], required: true }
    },
    parentDetails: {
        parentName: { type: String, required: true },
        mobileNumber: { type: String, required: true },
        address: { type: String, required: true }
    },
    status: {
        type: String,
        enum: ['Active', 'Inactive'],
        default: 'Active'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Student', studentSchema);
