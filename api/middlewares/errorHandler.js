const { sendResponse } = require('../utils/responseHelper');

const errorHandler = (err, req, res, next) => {
    console.error(err.stack);

    if (err.name === 'ValidationError') {
        const messages = Object.values(err.errors).map(val => val.message);
        return sendResponse(res, 400, 'Validation Error', messages);
    }

    if (err.code === 11000) {
        return sendResponse(res, 400, 'Duplicate Field Value Entered');
    }

    // Default error
    sendResponse(res, 500, err.message || 'Server Error');
};

module.exports = errorHandler;
