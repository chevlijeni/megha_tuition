const { check } = require('express-validator');

exports.createStudentValidate = [
    check('studentId', 'Student ID is required').notEmpty(),
    check('personalDetails.fullName', 'Full name is required').notEmpty(),
    check('personalDetails.gender', 'Gender must be Male, Female, or Other').isIn(['Male', 'Female', 'Other']),
    check('academicDetails.className', 'Class name is required').notEmpty(),
    check('academicDetails.board', 'Board must be GSEB or CBSC').isIn(['GSEB', 'CBSC']),
    check('academicDetails.batchTime', 'Batch time must be Morning, Afternoon, or Evening').isIn(['Morning', 'Afternoon', 'Evening']),
    check('academicDetails.enrollmentDate', 'Enrollment date is required').notEmpty(),
    check('feeDetails.feeAmount', 'Fee amount is required and must be numeric').isNumeric(),
    check('feeDetails.dueDayOfMonth', 'Due day must be between 1 and 31').isInt({ min: 1, max: 31 }),
    check('feeDetails.billCycle', 'Bill cycle must be Monthly, Quarterly, or Yearly').isIn(['Monthly', 'Quarterly', 'Yearly']),
    check('parentDetails.parentName', 'Parent name is required').notEmpty(),
    check('parentDetails.mobileNumber', 'Valid 10-digit mobile number is required').isLength({ min: 10, max: 10 }),
    check('parentDetails.address', 'Address is required').notEmpty()
];
