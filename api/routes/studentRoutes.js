const express = require('express');
const { getStudents, getStudent, createStudent, updateStudent, getDashboardStats, getPayments, collectPayment, getSyncData, getStudentPayments } = require('../controllers/studentController');
const { createStudentValidate } = require('../validations/studentValidation');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

// Apply auth middleware to all routes
router.use(protect);

router
    .route('/')
    .get(getStudents)
    .post(createStudentValidate, createStudent);

router.get('/sync', getSyncData);
router.get('/stats', getDashboardStats);
router.get('/payments', getPayments);
router.post('/collect-fee', collectPayment);

router.get('/:id/payments', getStudentPayments);

router
    .route('/:id')
    .get(getStudent)
    .put(updateStudent);

module.exports = router;
