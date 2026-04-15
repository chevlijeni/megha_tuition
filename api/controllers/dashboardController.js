const Student = require('../models/Student');
const Transaction = require('../models/Transaction');
const catchAsync = require('../utils/catchAsync');
const { sendResponse } = require('../utils/responseHelper');

// @desc    Get dashboard statistics
// @route   GET /api/v1/dashboard
// @access  Private
exports.getDashboardStats = catchAsync(async (req, res, next) => {
    // Count total students
    const totalStudents = await Student.countDocuments();

    // Calculate total collected fees
    const collectedResult = await Transaction.aggregate([
        { $group: { _id: null, total: { $sum: '$amountCollected' } } }
    ]);
    const collectedFees = collectedResult.length > 0 ? collectedResult[0].total : 0;

    // For pending and overdue, in a real app this would require checking against the current date,
    // due date, and expected amount over time. For simplicity, we calculate a mock or basic figure.
    // E.g. expected amount is the sum of all 'feeAmount'
    const expectedResult = await Student.aggregate([
        { $group: { _id: null, total: { $sum: '$feeDetails.feeAmount' } } }
    ]);
    const expectedFees = expectedResult.length > 0 ? expectedResult[0].total : 0;

    const pendingFees = Math.max(expectedFees - collectedFees, 0);

    const stats = {
        totalStudents,
        collectedFees,
        pendingFees,
        overdueFees: 0 // placeholder
    };

    sendResponse(res, 200, 'Success', stats);
});
