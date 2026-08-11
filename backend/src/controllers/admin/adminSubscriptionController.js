import { AppError } from '../../utils/appError.js';
import { subscriptionListQuerySchema } from '../../validators/admin.validator.js';
import * as adminSubscriptionService from '../../services/admin/adminSubscriptionService.js';

export const getSubscriptions = async (req, res, next) => {
  try {
    const { error, value } = subscriptionListQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);

    const data = await adminSubscriptionService.listSubscriptions(value);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getSubscriptionDetail = async (req, res, next) => {
  try {
    const data = await adminSubscriptionService.getSubscriptionDetail(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
