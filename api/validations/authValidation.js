const { check } = require('express-validator');

exports.registerValidate = [
    check('username', 'Please include a valid username').notEmpty(),
    check('password', 'Password is required').notEmpty()
];

exports.loginValidate = [
    check('username', 'Please include a valid username').notEmpty(),
    check('password', 'Password is required').exists()
];
