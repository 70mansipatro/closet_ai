import { roleHasPermission } from '../config/permissions.js';

export const requirePermission = (permission) => (req, res, next) => {
  if (!req.user || !roleHasPermission(req.user.role, permission)) {
    return res.status(403).json({ success: false, message: 'Permission denied', error: 'PERMISSION_DENIED' });
  }
  next();
};
