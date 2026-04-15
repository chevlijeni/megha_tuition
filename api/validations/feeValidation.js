const { check } = require('express-validator');

exports.createTransactionValidate = [
    check('student', 'Student reference is required').notEmpty(),
    check('amountCollected', 'Amount collected must be a number').isNumeric(),
    check('paymentMode', 'Payment mode is required (Cash, Online Payment, Bank Transfer)')
        .isIn(['Cash', 'Online Payment', 'Bank Transfer'])
];
