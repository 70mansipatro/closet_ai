import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { jwtConfig } from '../config/jwt.js';
import { AppError } from '../utils/appError.js';

export const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    console.log('[AUTH] protect middleware', {
      path: req.originalUrl,
      hasAuthorizationHeader: !!authHeader,
      tokenLength: token ? token.length : 0,
    });

    if (!token) {
      throw new AppError('Authentication required', 401);
    }

    const decoded = jwt.verify(token, jwtConfig.accessTokenSecret);
    console.log('[AUTH] JWT decoded', { userId: decoded.userId, role: decoded.role });

    const user = await User.findById(decoded.userId).select('-password');
    if (!user) {
      throw new AppError('User not found', 401);
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('[AUTH] protect middleware error', {
      path: req.originalUrl,
      errorName: error.name,
      errorMessage: error.message,
    });

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired' });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token' });
    }

    return res.status(error.statusCode || 401).json({ message: error.message || 'Authentication failed' });
  }
};

export const authorizeRoles = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return res.status(403).json({ message: 'Forbidden' });
  }
  next();
};
