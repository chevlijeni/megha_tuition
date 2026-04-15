const express = require('express');
const { getStudents, getStudent, createStudent, updateStudent } = require('../controllers/studentController');
const { createStudentValidate } = require('../validations/studentValidation');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

// Apply auth middleware to all routes
router.use(protect);

router
    .route('/')
    .get(getStudents)
    .post(createStudentValidate, createStudent);

router
    .route('/:id')
    .get(getStudent)
    .put(updateStudent);

module.exports = router;
