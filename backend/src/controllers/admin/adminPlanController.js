import { AppError } from '../../utils/appError.js';
import { planCreateSchema, planUpdateSchema, planStatusUpdateSchema } from '../../validators/admin.validator.js';
import * as adminPlanService from '../../services/admin/adminPlanService.js';
import { logAction } from '../../services/admin/adminAuditService.js';

export const getPlans = async (req, res, next) => {
  try {
    const data = await adminPlanService.listPlans();
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const createPlan = async (req, res, next) => {
  try {
    const { error, value } = planCreateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const plan = await adminPlanService.createPlan(value);

    await logAction({
      adminUserId: req.user._id,
      action: 'PLAN_CREATED',
      targetType: 'SubscriptionPlan',
      targetId: plan._id,
      description: `Created plan ${plan.planCode}`,
      req,
    });

    res.status(201).json({ success: true, data: plan, message: 'Plan created' });
  } catch (error) {
    next(error);
  }
};

export const updatePlan = async (req, res, next) => {
  try {
    const { error, value } = planUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const plan = await adminPlanService.updatePlan(req.params.id, value);

    await logAction({
      adminUserId: req.user._id,
      action: 'PLAN_UPDATED',
      targetType: 'SubscriptionPlan',
      targetId: req.params.id,
      description: `Updated plan ${plan.planCode}`,
      req,
    });

    res.status(200).json({ success: true, data: plan, message: 'Plan updated' });
  } catch (error) {
    next(error);
  }
};

export const setPlanStatus = async (req, res, next) => {
  try {
    const { error, value } = planStatusUpdateSchema.validate(req.body);
    if (error) throw new AppError(error.details[0].message, 400);

    const { plan, note } = await adminPlanService.setPlanStatus(req.params.id, value.isActive);

    await logAction({
      adminUserId: req.user._id,
      action: value.isActive ? 'PLAN_ACTIVATED' : 'PLAN_DEACTIVATED',
      targetType: 'SubscriptionPlan',
      targetId: req.params.id,
      description: note || `Set plan status to ${value.isActive ? 'active' : 'inactive'}`,
      req,
    });

    res.status(200).json({ success: true, data: plan, message: note || 'Plan status updated' });
  } catch (error) {
    next(error);
  }
};
