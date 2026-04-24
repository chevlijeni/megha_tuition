const { validationResult } = require('express-validator');
const Student = require('../models/Student');
const Payment = require('../models/Payment');
const catchAsync = require('../utils/catchAsync');
const { sendResponse } = require('../utils/responseHelper');
const WhatsAppService = require('../utils/whatsappService');

// @desc    Sync all home data (stats, students, payments)
// @route   GET /api/v1/students/sync
// @access  Private
exports.getSyncData = catchAsync(async (req, res, next) => {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    // 1. Get Stats (Simplified logic from getDashboardStats)
    const totalStudents = await Student.countDocuments({ status: 'Active' });
    const studentsListRaw = await Student.find({ status: 'Active' }, 'feeDetails.feeAmount');
    const totalFees = studentsListRaw.reduce((sum, s) => sum + (s.feeDetails.feeAmount || 0), 0);
    const paymentsCurrentMonth = await Payment.find({ month: currentMonth, year: currentYear });
    const totalCollection = paymentsCurrentMonth.reduce((sum, p) => sum + (p.amount || 0), 0);
    const pendingFees = totalFees - totalCollection;

    const startOfToday = new Date(new Date().setHours(0, 0, 0, 0));
    const endOfToday = new Date(new Date().setHours(23, 59, 59, 999));
    const todayPayments = await Payment.find({ paymentDate: { $gte: startOfToday, $lte: endOfToday } });
    const collectedToday = todayPayments.reduce((sum, p) => sum + (p.amount || 0), 0);
    const transactionsToday = todayPayments.length;

    const stats = {
        totalStudents,
        totalFees,
        totalCollection,
        pendingFees,
        collectedToday,
        transactionsToday
    };

    // 2. Get Students (Logic from getStudents)
    const students = await Student.aggregate([
        {
            $lookup: {
                from: 'payments',
                let: { studentId: '$_id' },
                pipeline: [
                    {
                        $match: {
                            $expr: {
                                $and: [
                                    { $eq: ['$student', '$$studentId'] },
                                    { $eq: ['$month', currentMonth] },
                                    { $eq: ['$year', currentYear] }
                                ]
                            }
                        }
                    }
                ],
                as: 'currentMonthPayment'
            }
        },
        {
            $addFields: {
                isPaidCurrentMonth: { $gt: [{ $size: '$currentMonthPayment' }, 0] },
                paymentDetails: { $arrayElemAt: ['$currentMonthPayment', 0] }
            }
        },
        { $sort: { createdAt: -1 } }
    ]);

    // 3. Get Recent Payments (Logic from getPayments)
    const payments = await Payment.find()
        .populate('student', 'personalDetails academicDetails studentId')
        .sort({ paymentDate: -1 })
        .limit(20); // Only return last 20 for sync, others can be paginated if needed later

    // 4. Monthly Earnings for 6 months
    const monthlyEarnings = await Payment.aggregate([
        { $group: { _id: { month: "$month", year: "$year" }, total: { $sum: "$amount" } } },
        { $sort: { "_id.year": -1, "_id.month": -1 } },
        { $limit: 6 }
    ]);

    sendResponse(res, 200, 'Sync Successful', {
        stats,
        students,
        payments,
        monthlyEarnings
    });
});

// @desc    Get all students with payment status for current month
// @route   GET /api/v1/students
// @access  Private
exports.getStudents = catchAsync(async (req, res, next) => {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    const students = await Student.aggregate([
        {
            $lookup: {
                from: 'payments',
                let: { studentId: '$_id' },
                pipeline: [
                    {
                        $match: {
                            $expr: {
                                $and: [
                                    { $eq: ['$student', '$$studentId'] },
                                    { $eq: ['$month', currentMonth] },
                                    { $eq: ['$year', currentYear] }
                                ]
                            }
                        }
                    }
                ],
                as: 'currentMonthPayment'
            }
        },
        {
            $addFields: {
                isPaidCurrentMonth: { $gt: [{ $size: '$currentMonthPayment' }, 0] },
                paymentDetails: { $arrayElemAt: ['$currentMonthPayment', 0] }
            }
        },
        { $sort: { createdAt: -1 } }
    ]);
    
    sendResponse(res, 200, 'Success', students);
});

// @desc    Get single student with payment status
// @route   GET /api/v1/students/:id
// @access  Private
exports.getStudent = catchAsync(async (req, res, next) => {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();
    const mongoose = require('mongoose');

    const result = await Student.aggregate([
        { $match: { _id: new mongoose.Types.ObjectId(req.params.id) } },
        {
            $lookup: {
                from: 'payments',
                let: { studentId: '$_id' },
                pipeline: [
                    {
                        $match: {
                            $expr: {
                                $and: [
                                    { $eq: ['$student', '$$studentId'] },
                                    { $eq: ['$month', currentMonth] },
                                    { $eq: ['$year', currentYear] }
                                ]
                            }
                        }
                    }
                ],
                as: 'currentMonthPayment'
            }
        },
        {
            $addFields: {
                isPaidCurrentMonth: { $gt: [{ $size: '$currentMonthPayment' }, 0] },
                paymentDetails: { $arrayElemAt: ['$currentMonthPayment', 0] }
            }
        }
    ]);

    if (!result || result.length === 0) {
        return sendResponse(res, 404, 'Student not found');
    }
    
    sendResponse(res, 200, 'Success', result[0]);
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

// @desc    Get payments for a specific student
// @route   GET /api/v1/students/:id/payments
// @access  Private
exports.getStudentPayments = catchAsync(async (req, res, next) => {
    const student = await Student.findById(req.params.id);
    if (!student) {
        return sendResponse(res, 404, 'Student not found');
    }

    const payments = await Payment.find({ student: req.params.id })
        .sort({ paymentDate: -1 });
    
    sendResponse(res, 200, 'Success', {
        student,
        payments
    });
});

// @desc    Collect fee payment
// @route   POST /api/v1/students/collect-fee
// @access  Private
exports.collectPayment = catchAsync(async (req, res, next) => {
    const { studentId, amount, paymentMethod, referenceNumber } = req.body;

    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    // Check if payment already exists for this month
    const existingPayment = await Payment.findOne({
        student: studentId,
        month: currentMonth,
        year: currentYear
    });

    if (existingPayment) {
        return sendResponse(res, 400, 'Fees for this month already collected for this student.');
    }

    const payment = await Payment.create({
        student: studentId,
        amount,
        month: currentMonth,
        year: currentYear,
        paymentMethod,
        receiptNumber: referenceNumber || `RCPT-${Date.now()}`
    });

    // Populate student details for receipt generation and WhatsApp automation
    const populatedPayment = await Payment.findById(payment._id)
        .populate('student', 'personalDetails parentDetails studentId feeDetails academicDetails');

    // Trigger WhatsApp notification from backend
    if (populatedPayment.student && populatedPayment.student.parentDetails) {
        const studentObj = populatedPayment.student;
        WhatsAppService.sendFeeConfirmation({
            parentName: studentObj.parentDetails.parentName,
            mobileNumber: studentObj.parentDetails.mobileNumber,
            studentName: studentObj.personalDetails.fullName,
            amount: populatedPayment.amount,
            month: new Date().toLocaleString('default', { month: 'long' }),
            year: new Date().getFullYear().toString()
        }).catch(err => console.error('Auto-WhatsApp Error:', err));
    }

    sendResponse(res, 201, 'Payment collected successfully', populatedPayment);
});
