const express = require('express');
const { register, login } = require('../controllers/authController');
const { registerValidate, loginValidate } = require('../validations/authValidation');

const router = express.Router();

router.post('/register', registerValidate, register);
router.post('/login', loginValidate, login);

module.exports = router;
