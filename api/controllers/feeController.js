const { validationResult } = require('express-validator');
const Transaction = require('../models/Transaction');
const catchAsync = require('../utils/catchAsync');
const { sendResponse } = require('../utils/responseHelper');

// @desc    Get all transactions
// @route   GET /api/v1/fees
// @access  Private
exports.getTransactions = catchAsync(async (req, res, next) => {
    const transactions = await Transaction.find().populate('student', 'personalDetails.fullName studentId').sort({ paymentDate: -1 });
    sendResponse(res, 200, 'Success', transactions);
});

// @desc    Create new fee transaction
// @route   POST /api/v1/fees
// @access  Private
exports.createTransaction = catchAsync(async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return sendResponse(res, 400, 'Validation Error', errors.array().map(e => e.msg));
    }

    const transaction = await Transaction.create(req.body);
    
    // Populate student details so frontend can immediately generate receipt
    const populatedTransaction = await Transaction.findById(transaction._id)
        .populate('student', 'personalDetails parentDetails studentId feeDetails academicDetails');

    sendResponse(res, 201, 'Transaction created successfully', populatedTransaction);
});
