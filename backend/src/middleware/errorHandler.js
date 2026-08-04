export const errorHandler = (err, req, res, next) => {
  const status = err.statusCode || err.status || 500;
  const isDevelopment = process.env.NODE_ENV !== 'production';

  console.error('[ERROR HANDLER] request failed', {
    method: req.method,
    path: req.originalUrl,
    name: err.name,
    code: err.code,
    message: err.message,
    statusCode: status,
    stack: err.stack,
    details: err.details,
  });

  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ success: false, message: 'File size too large', error: err.name || 'PayloadTooLarge', stack: isDevelopment ? err.stack : undefined });
  }

  if (err.message === 'Only image files are allowed') {
    return res.status(400).json({ success: false, message: err.message, error: err.name || 'ValidationError', stack: isDevelopment ? err.stack : undefined });
  }

  if (err.code === 11000 || err.code === 11001) {
    return res.status(409).json({ success: false, message: 'Email already registered', error: 'DuplicateKeyError', stack: isDevelopment ? err.stack : undefined });
  }

  if (err.name === 'ValidationError' || err.isJoi) {
    return res.status(400).json({ success: false, message: err.message || 'Validation failed', error: err.name || 'ValidationError', stack: isDevelopment ? err.stack : undefined });
  }

  if (err instanceof SyntaxError && err.type === 'entity.parse.failed') {
    return res.status(400).json({ success: false, message: 'Invalid JSON payload', error: err.name || 'SyntaxError', stack: isDevelopment ? err.stack : undefined });
  }

  res.status(status).json({
    success: false,
    message: err.message || 'Internal server error',
    error: err.name || err.code || 'Error',
    details: err.details,
    stack: isDevelopment ? err.stack : undefined,
  });
};
