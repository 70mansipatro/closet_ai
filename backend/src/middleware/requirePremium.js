import { AppError } from '../utils/appError.js';
import { getUserSubscriptionStatus } from '../services/subscriptionService.js';

export const requirePremium = async (req, res, next) => {
  try {
    const userId = req.user?._id || req.user?.userId;
    if (!userId) throw new AppError('Authentication required', 401);

    const subscription = await getUserSubscriptionStatus(userId);
    if (!subscription || subscription.status !== 'active' || !subscription.isEntitled) {
      throw new AppError('Upgrade to Premium to continue using this feature.', 403, { code: 'PREMIUM_REQUIRED' });
    }

    next();
  } catch (error) {
    next(error);
  }
};
