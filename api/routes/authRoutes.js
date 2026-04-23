const express = require('express');
const { register, login, getMe, updateMe } = require('../controllers/authController');
const { registerValidate, loginValidate } = require('../validations/authValidation');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.post('/register', registerValidate, register);
router.post('/login', loginValidate, login);
router.get('/me', protect, getMe);
router.put('/me', protect, updateMe);

module.exports = router;
