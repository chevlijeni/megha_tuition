const { check } = require('express-validator');

exports.registerValidate = [
    check('username', 'Please include a valid username').notEmpty(),
    check('password', 'Please enter a password with 6 or more characters').isLength({ min: 6 })
];

exports.loginValidate = [
    check('username', 'Please include a valid username').notEmpty(),
    check('password', 'Password is required').exists()
];
