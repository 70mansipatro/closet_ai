import AdminAuditLog from '../../models/AdminAuditLog.js';

export const logAction = async ({ adminUserId, action, targetType = '', targetId = '', description = '', req }) => {
  try {
    await AdminAuditLog.create({
      adminUserId,
      action,
      targetType,
      targetId: targetId ? String(targetId) : '',
      description,
      ipAddress: req?.ip || req?.headers?.['x-forwarded-for'] || '',
      userAgent: req?.headers?.['user-agent'] || '',
    });
  } catch (error) {
    console.error('[ADMIN AUDIT] failed to record audit log', { action, targetType, targetId, error: error.message });
  }
};

export const listAuditLogs = async ({ page = 1, limit = 20, action, adminUserId, from, to }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);

  const match = {};
  if (action) match.action = action;
  if (adminUserId) match.adminUserId = adminUserId;
  if (from || to) {
    match.createdAt = {};
    if (from) match.createdAt.$gte = new Date(from);
    if (to) match.createdAt.$lte = new Date(to);
  }

  const [items, total] = await Promise.all([
    AdminAuditLog.find(match)
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .populate('adminUserId', 'name email role')
      .lean(),
    AdminAuditLog.countDocuments(match),
  ]);

  return {
    items,
    page: safePage,
    limit: safeLimit,
    total,
    totalPages: Math.max(Math.ceil(total / safeLimit), 1),
  };
};
