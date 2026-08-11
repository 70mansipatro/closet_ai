import SubscriptionPlan from '../../models/SubscriptionPlan.js';
import Subscription from '../../models/Subscription.js';
import { AppError } from '../../utils/appError.js';

export const listPlans = async () => {
  return SubscriptionPlan.find().sort({ sortOrder: 1, price: 1 }).lean();
};

export const createPlan = async (data) => {
  const existing = await SubscriptionPlan.findOne({ planCode: data.planCode }).lean();
  if (existing) throw new AppError('A plan with this code already exists', 409, { code: 'PLAN_EXISTS' });
  return SubscriptionPlan.create(data);
};

export const updatePlan = async (id, data) => {
  const plan = await SubscriptionPlan.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  if (!plan) throw new AppError('Plan not found', 404, { code: 'PLAN_NOT_FOUND' });
  return plan;
};

export const setPlanStatus = async (id, isActive) => {
  const plan = await SubscriptionPlan.findById(id);
  if (!plan) throw new AppError('Plan not found', 404, { code: 'PLAN_NOT_FOUND' });

  if (!isActive) {
    const activeSubscribers = await Subscription.countDocuments({ planId: id, status: 'active' });
    if (activeSubscribers > 0) {
      plan.isActive = false;
      await plan.save();
      return { plan, note: `Deactivated. ${activeSubscribers} existing subscriber(s) keep their current plan history.` };
    }
  }

  plan.isActive = isActive;
  await plan.save();
  return { plan, note: null };
};
