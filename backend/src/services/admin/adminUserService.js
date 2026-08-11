import mongoose from 'mongoose';
import User from '../../models/User.js';
import Subscription from '../../models/Subscription.js';
import Clothing from '../../models/Clothing.js';
import Outfit from '../../models/Outfit.js';
import Trip from '../../models/Trip.js';
import LaundryHistory from '../../models/LaundryHistory.js';
import FeatureUsage from '../../models/FeatureUsage.js';
import RefreshToken from '../../models/RefreshToken.js';
import { AppError } from '../../utils/appError.js';

const buildUserMatch = ({ search, status, subscription, role }) => {
  const match = {};

  if (search) {
    const regex = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    match.$or = [{ name: regex }, { email: regex }];
    if (mongoose.Types.ObjectId.isValid(search)) {
      match.$or.push({ _id: search });
    }
  }

  if (status) match.status = status;
  if (role) match.role = role;

  if (subscription === 'premium') {
    match.subscriptionStatus = 'active';
  } else if (subscription === 'free') {
    match.subscriptionStatus = { $in: ['free', 'expired', 'cancelled', 'past_due'] };
  }

  return match;
};

export const listUsers = async ({ page = 1, limit = 20, search, status, subscription, role }) => {
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const match = buildUserMatch({ search, status, subscription, role });

  const [items, total] = await Promise.all([
    User.find(match)
      .select('-password -otp -otpExpiresAt -refreshToken')
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .lean(),
    User.countDocuments(match),
  ]);

  return {
    items,
    page: safePage,
    limit: safeLimit,
    total,
    totalPages: Math.max(Math.ceil(total / safeLimit), 1),
  };
};

export const getUserDetail = async (userId) => {
  const user = await User.findById(userId).select('-password -otp -otpExpiresAt -refreshToken').lean();
  if (!user) throw new AppError('User not found', 404, { code: 'USER_NOT_FOUND' });

  const [subscription, wardrobeCount, outfitCount, tripCount, laundryCount, aiUsage] = await Promise.all([
    Subscription.findOne({ userId }).sort({ createdAt: -1 }).lean(),
    Clothing.countDocuments({ userId }),
    Outfit.countDocuments({ userId }),
    Trip.countDocuments({ owner: userId }),
    LaundryHistory.countDocuments({ userId }),
    FeatureUsage.find({ userId }).lean(),
  ]);

  return {
    ...user,
    subscription,
    wardrobeCount,
    outfitCount,
    tripCount,
    laundryCount,
    aiUsage: aiUsage.map((entry) => ({ feature: entry.feature, count: entry.count, period: entry.period })),
  };
};

export const updateUserStatus = async (userId, status) => {
  const user = await User.findById(userId);
  if (!user) throw new AppError('User not found', 404, { code: 'USER_NOT_FOUND' });

  user.status = status;
  await user.save();

  if (status === 'suspended') {
    await RefreshToken.deleteMany({ user: userId });
  }

  return user.toObject({ getters: false, versionKey: false });
};

export const updateUserRole = async ({ actingAdmin, targetUserId, role }) => {
  if (String(actingAdmin._id) === String(targetUserId)) {
    throw new AppError('You cannot change your own role', 403, { code: 'INVALID_ROLE' });
  }

  const targetUser = await User.findById(targetUserId);
  if (!targetUser) throw new AppError('User not found', 404, { code: 'USER_NOT_FOUND' });

  if (role === 'super_admin' && actingAdmin.role !== 'super_admin') {
    throw new AppError('Only a super admin can grant super admin access', 403, { code: 'PERMISSION_DENIED' });
  }

  if (targetUser.role === 'super_admin' && actingAdmin.role !== 'super_admin') {
    throw new AppError('Only a super admin can change another super admin', 403, { code: 'PERMISSION_DENIED' });
  }

  targetUser.role = role;
  await targetUser.save();
  return targetUser.toObject({ getters: false, versionKey: false });
};

export const deleteUser = async ({ actingAdmin, targetUserId }) => {
  const targetUser = await User.findById(targetUserId);
  if (!targetUser) throw new AppError('User not found', 404, { code: 'USER_NOT_FOUND' });

  if (targetUser.role === 'super_admin' && actingAdmin.role !== 'super_admin') {
    throw new AppError('Super admin accounts cannot be deleted by a regular admin', 403, { code: 'PERMISSION_DENIED' });
  }

  targetUser.status = 'inactive';
  targetUser.name = 'Deleted User';
  targetUser.email = `deleted_${targetUser._id}@removed.closetai.local`;
  targetUser.phone = '';
  targetUser.profileImage = '';
  await targetUser.save();

  await RefreshToken.deleteMany({ user: targetUserId });

  return { id: targetUser._id };
};
