const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    student: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Student',
        required: true
    },
    amountCollected: {
        type: Number,
        required: true
    },
    paymentMode: {
        type: String,
        enum: ['Cash', 'Online Payment', 'Bank Transfer'],
        required: true
    },
    referenceNumber: {
        type: String
    },
    paymentDate: {
        type: Date,
        default: Date.now
    },
    status: {
        type: String,
        enum: ['Success', 'Failed'],
        default: 'Success'
    }
});

module.exports = mongoose.model('Transaction', transactionSchema);
