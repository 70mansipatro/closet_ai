import { getDashboardSummary } from '../../services/admin/adminDashboardService.js';

export const getDashboard = async (req, res, next) => {
  try {
    const data = await getDashboardSummary({ range: req.query.range });
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
