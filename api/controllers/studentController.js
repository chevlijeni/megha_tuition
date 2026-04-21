const { validationResult } = require('express-validator');
const Student = require('../models/Student');
const Payment = require('../models/Payment');
const catchAsync = require('../utils/catchAsync');
const { sendResponse } = require('../utils/responseHelper');

// @desc    Get all students
// @route   GET /api/v1/students
// @access  Private
exports.getStudents = catchAsync(async (req, res, next) => {
    const students = await Student.find().sort({ createdAt: -1 });
    sendResponse(res, 200, 'Success', students);
});

// @desc    Get single student
// @route   GET /api/v1/students/:id
// @access  Private
exports.getStudent = catchAsync(async (req, res, next) => {
    const student = await Student.findById(req.params.id);
    if (!student) {
        return sendResponse(res, 404, 'Student not found');
    }
    sendResponse(res, 200, 'Success', student);
});

// @desc    Create new student
// @route   POST /api/v1/students
// @access  Private
exports.createStudent = catchAsync(async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return sendResponse(res, 400, 'Validation Error', errors.array().map(e => e.msg));
    }

    const existingStudent = await Student.findOne({ studentId: req.body.studentId });
    if (existingStudent) {
        return sendResponse(res, 400, 'Student ID already exists');
    }

    const student = await Student.create(req.body);
    sendResponse(res, 201, 'Student created successfully', student);
});

exports.updateStudent = catchAsync(async (req, res, next) => {
    const student = await Student.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true
    });

    if (!student) {
        return sendResponse(res, 404, 'Student not found');
    }
    sendResponse(res, 200, 'Student updated successfully', student);
});

// @desc    Get dashboard statistics
// @route   GET /api/v1/students/stats
// @access  Private
exports.getDashboardStats = catchAsync(async (req, res, next) => {
    const totalStudents = await Student.countDocuments({ status: 'Active' });
    
    // Calculate total expected fees (all active students)
    const students = await Student.find({ status: 'Active' }, 'feeDetails.feeAmount');
    const totalFees = students.reduce((sum, s) => sum + (s.feeDetails.feeAmount || 0), 0);

    // Calculate current month's collection
    const now = new Date();
    const currentMonth = now.getMonth() + 1; // 1-12
    const currentYear = now.getFullYear();

    const payments = await Payment.find({
        month: currentMonth,
        year: currentYear
    });

    const totalCollection = payments.reduce((sum, p) => sum + (p.amount || 0), 0);
    const pendingFees = totalFees - totalCollection;

    // Calculate today's stats
    const startOfToday = new Date(now.setHours(0, 0, 0, 0));
    const endOfToday = new Date(now.setHours(23, 59, 59, 999));
    
    const todayPayments = await Payment.find({
        paymentDate: {
            $gte: startOfToday,
            $lte: endOfToday
        }
    });

    const collectedToday = todayPayments.reduce((sum, p) => sum + (p.amount || 0), 0);
    const transactionsToday = todayPayments.length;

    sendResponse(res, 200, 'Success', {
        totalStudents,
        totalFees,
        totalCollection,
        pendingFees,
        collectedToday,
        transactionsToday
    });
});

// @desc    Get all payments
// @route   GET /api/v1/students/payments
// @access  Private
exports.getPayments = catchAsync(async (req, res, next) => {
    const payments = await Payment.find()
        .populate('student', 'personalDetails academicDetails studentId')
        .sort({ paymentDate: -1 });
    
    sendResponse(res, 200, 'Success', payments);
});

// @desc    Collect fee payment
// @route   POST /api/v1/students/collect-fee
// @access  Private
exports.collectPayment = catchAsync(async (req, res, next) => {
    const { studentId, amount, paymentMethod, referenceNumber } = req.body;

    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    const payment = await Payment.create({
        student: studentId,
        amount,
        month: currentMonth,
        year: currentYear,
        paymentMethod,
        receiptNumber: referenceNumber || `RCPT-${Date.now()}`
    });

    sendResponse(res, 201, 'Payment collected successfully', payment);
});
