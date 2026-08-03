export const errorHandler = (err, req, res, next) => {
  console.error(err);

  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ message: 'File size too large' });
  }

  if (err.message === 'Only image files are allowed') {
    return res.status(400).json({ message: err.message });
  }

  const status = err.status || 500;
  res.status(status).json({
    message: err.message || 'Internal server error',
  });
};
