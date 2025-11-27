/**
 * Global error handler middleware
 * Catches all unhandled errors and returns appropriate HTTP responses
 * Prevents server crashes
 */

function errorHandler(err, req, res, next) {
    console.error('[ERROR HANDLER] Caught error:');
    console.error('[ERROR HANDLER] URL:', req.method, req.originalUrl);
    console.error('[ERROR HANDLER] Error:', err.message);

    if (err.stack) {
        console.error('[ERROR HANDLER] Stack:', err.stack);
    }

    // Determine status code
    let statusCode = 500;
    let errorResponse = {
        error: 'Internal Server Error',
        message: 'An unexpected error occurred'
    };

    // Handle specific error types
    if (err.code === 'ORA-06550') {
        // Oracle PL/SQL compilation error
        statusCode = 500;
        errorResponse = {
            error: 'Database Procedure Error',
            message: 'The requested database procedure could not be executed',
            details: process.env.NODE_ENV === 'development' ? err.message : undefined
        };
    } else if (err.code && err.code.startsWith('ORA-')) {
        // Generic Oracle error
        statusCode = 500;
        errorResponse = {
            error: 'Database Error',
            message: 'A database error occurred',
            code: err.code,
            details: process.env.NODE_ENV === 'development' ? err.message : undefined
        };
    } else if (err.name === 'ValidationError') {
        // Validation errors
        statusCode = 400;
        errorResponse = {
            error: 'Validation Error',
            message: err.message
        };
    } else if (err.statusCode) {
        // Errors with explicit status codes
        statusCode = err.statusCode;
        errorResponse = {
            error: err.name || 'Error',
            message: err.message
        };
    }

    // Add additional debug info in development
    if (process.env.NODE_ENV === 'development') {
        errorResponse.package = err.package;
        errorResponse.procedure = err.procedure;
        errorResponse.stack = err.stack;
    }

    // Send response
    res.status(statusCode).json(errorResponse);
}

/**
 * Async error wrapper
 * Wraps async route handlers to catch promise rejections
 */
function asyncHandler(fn) {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
}

/**
 * 404 Not Found handler
 */
function notFoundHandler(req, res) {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.originalUrl} not found`
    });
}

module.exports = {
    errorHandler,
    asyncHandler,
    notFoundHandler
};