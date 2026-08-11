import { AppError } from '../../utils/appError.js';
import { settingsUpdateSchema } from '../../validators/admin.validator.js';
import * as adminSettingsService from '../../services/admin/adminSettingsService.js';
import { logAction } from '../../services/admin/adminAuditService.js';

export const getSettings = async (req, res, next) => {
  try {
    const data = await adminSettingsService.getSettings();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const updateSettings = async (req, res, next) => {
  try {
    const { error, value } = settingsUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const data = await adminSettingsService.updateSettings({ ...value, updatedBy: req.user._id });

    await logAction({
      adminUserId: req.user._id,
      action: 'SETTINGS_CHANGED',
      targetType: 'AdminSettings',
      targetId: data._id,
      description: 'Updated admin settings',
      req,
    });

    res.status(200).json({ success: true, data, message: 'Settings updated' });
  } catch (error) {
    next(error);
  }
};
