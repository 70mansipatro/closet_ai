export const sendSuccess = (res, statusCode = 200, payload = {}) => {
  return res.status(statusCode).json(payload);
};

export const sendError = (res, statusCode = 500, message = 'Internal server error') => {
  return res.status(statusCode).json({ message });
};
