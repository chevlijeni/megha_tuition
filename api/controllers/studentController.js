const { validationResult } = require('express-validator');
const Student = require('../models/Student');
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

// @desc    Update student
// @route   PUT /api/v1/students/:id
// @access  Private
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
