import { AppError } from '../utils/appError.js';
import { getFeatureUsage, incrementFeatureUsage } from '../services/subscriptionService.js';

export const checkFeatureLimit = (feature) => async (req, res, next) => {
  try {
    const userId = req.user?._id || req.user?.userId;
    if (!userId) throw new AppError('Authentication required', 401);

    const usage = await getFeatureUsage({ userId, feature });
    const limit = usage.limit;

    if (!usage.isPremium && usage.count >= limit) {
      throw new AppError('Upgrade to Premium to continue using this feature.', 403, { code: 'PREMIUM_REQUIRED' });
    }

    const updated = await incrementFeatureUsage({ userId, feature, isPremium: usage.isPremium });
    req.featureUsage = updated;
    next();
  } catch (error) {
    next(error);
  }
};
