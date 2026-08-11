import { AppError } from '../../utils/appError.js';
import { paymentListQuerySchema } from '../../validators/admin.validator.js';
import * as adminPaymentService from '../../services/admin/adminPaymentService.js';

export const getPayments = async (req, res, next) => {
  try {
    const { error, value } = paymentListQuerySchema.validate(req.query);
    if (error) throw new AppError(error.details[0].message, 400);

    const data = await adminPaymentService.listPayments(value);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getPaymentDetail = async (req, res, next) => {
  try {
    const data = await adminPaymentService.getPaymentDetail(req.params.id);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
