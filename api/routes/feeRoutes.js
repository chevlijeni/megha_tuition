const express = require('express');
const { getTransactions, createTransaction } = require('../controllers/feeController');
const { createTransactionValidate } = require('../validations/feeValidation');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

// Apply auth middleware to all routes
router.use(protect);

router
    .route('/')
    .get(getTransactions)
    .post(createTransactionValidate, createTransaction);

module.exports = router;
