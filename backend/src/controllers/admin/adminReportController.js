import { AppError } from '../../utils/appError.js';
import { reportExportSchema } from '../../validators/admin.validator.js';
import { generateReport, listReportTypes } from '../../services/admin/adminReportService.js';
import { logAction } from '../../services/admin/adminAuditService.js';

export const getReportTypes = async (req, res, next) => {
  try {
    res.status(200).json({ success: true, data: listReportTypes() });
  } catch (error) {
    next(error);
  }
};

export const exportReport = async (req, res, next) => {
  try {
    const { error, value } = reportExportSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400, { code: 'EXPORT_FAILED' });

    const { csv, filename, count } = await generateReport(value);

    await logAction({
      adminUserId: req.user._id,
      action: 'REPORT_EXPORTED',
      targetType: 'Report',
      targetId: value.type,
      description: `Exported ${value.type} report (${count} rows, ${value.format})`,
      req,
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.status(200).send(csv);
  } catch (error) {
    next(error);
  }
};
