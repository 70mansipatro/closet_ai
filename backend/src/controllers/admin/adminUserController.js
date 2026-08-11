import { AppError } from '../../utils/appError.js';
import { userListQuerySchema, userStatusUpdateSchema, userRoleUpdateSchema } from '../../validators/admin.validator.js';
import * as adminUserService from '../../services/admin/adminUserService.js';
import { logAction } from '../../services/admin/adminAuditService.js';

export const getUsers = async (req, res, next) => {
  try {
    const { error, value } = userListQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);

    const data = await adminUserService.listUsers(value);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getUserDetail = async (req, res, next) => {
  try {
    const data = await adminUserService.getUserDetail(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateUserStatus = async (req, res, next) => {
  try {
    const { error, value } = userStatusUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400, { code: 'INVALID_STATUS' });

    const user = await adminUserService.updateUserStatus(req.params.id, value.status);

    await logAction({
      adminUserId: req.user._id,
      action: value.status === 'suspended' ? 'USER_SUSPENDED' : value.status === 'active' ? 'USER_ACTIVATED' : 'USER_STATUS_CHANGED',
      targetType: 'User',
      targetId: req.params.id,
      description: `Set user status to ${value.status}`,
      req,
    });

    res.status(200).json({ success: true, data: user, message: 'User status updated' });
  } catch (error) {
    next(error);
  }
};

export const updateUserRole = async (req, res, next) => {
  try {
    const { error, value } = userRoleUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400, { code: 'INVALID_ROLE' });

    const user = await adminUserService.updateUserRole({
      actingAdmin: req.user,
      targetUserId: req.params.id,
      role: value.role,
    });

    await logAction({
      adminUserId: req.user._id,
      action: 'USER_ROLE_CHANGED',
      targetType: 'User',
      targetId: req.params.id,
      description: `Changed role to ${value.role}`,
      req,
    });

    res.status(200).json({ success: true, data: user, message: 'User role updated' });
  } catch (error) {
    next(error);
  }
};

export const deleteUser = async (req, res, next) => {
  try {
    const result = await adminUserService.deleteUser({ actingAdmin: req.user, targetUserId: req.params.id });

    await logAction({
      adminUserId: req.user._id,
      action: 'USER_DELETED',
      targetType: 'User',
      targetId: req.params.id,
      description: 'Soft-deleted user account',
      req,
    });

    res.status(200).json({ success: true, data: result, message: 'User deleted' });
  } catch (error) {
    next(error);
  }
};
