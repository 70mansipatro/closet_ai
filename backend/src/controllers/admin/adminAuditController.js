import { AppError } from '../../utils/appError.js';
import { auditLogQuerySchema } from '../../validators/admin.validator.js';
import { listAuditLogs } from '../../services/admin/adminAuditService.js';

export const getAuditLogs = async (req, res, next) => {
  try {
    const { error, value } = auditLogQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);

    const data = await listAuditLogs(value);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
