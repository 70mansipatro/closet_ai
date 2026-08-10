import { AppError } from '../utils/appError.js';
import { createWearHistory, findWearHistoryForUser, findWearHistoryByClothing, findWearHistoryByOutfit } from '../repositories/history.repository.js';
import Clothing from '../models/Clothing.js';
import WearHistory from '../models/WearHistory.js';
import Outfit from '../models/Outfit.js';

export const listHistory = async (req, res, next) => {
  try {
    const { page, limit, search, startDate, endDate } = req.query;
    const result = await findWearHistoryForUser({ userId: req.user._id, page, limit, search, startDate: startDate ? new Date(startDate) : null, endDate: endDate ? new Date(endDate) : null });
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

export const clothingHistory = async (req, res, next) => {
  try {
    const clothingId = req.params.id;
    const items = await findWearHistoryByClothing({ userId: req.user._id, clothingId });
    res.status(200).json({ success: true, data: items });
  } catch (error) {
    next(error);
  }
};

export const outfitHistory = async (req, res, next) => {
  try {
    const outfitId = req.params.id;
    const items = await findWearHistoryByOutfit({ userId: req.user._id, outfitId });
    res.status(200).json({ success: true, data: items });
  } catch (error) {
    next(error);
  }
};

export const stats = async (req, res, next) => {
  try {
    const userId = req.user._id;

    const mostWorn = await Clothing.find({ userId }).sort({ wearCount: -1 }).limit(5);
    const leastWorn = await Clothing.find({ userId }).sort({ wearCount: 1 }).limit(5);
    const neverWorn = await Clothing.find({ userId, $or: [{ wearCount: 0 }, { wearCount: { $exists: false } }] }).limit(10);
    const lastWorn = await Clothing.find({ userId, lastWorn: { $exists: true } }).sort({ lastWorn: -1 }).limit(10);

    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const startOfWeek = new Date();
    const day = startOfWeek.getDay();
    const diff = startOfWeek.getDate() - day + (day === 0 ? -6 : 1);
    startOfWeek.setDate(diff);
    startOfWeek.setHours(0, 0, 0, 0);

    const monthlyCount = await WearHistory.countDocuments({ userId, date: { $gte: startOfMonth } });
    const weeklyCount = await WearHistory.countDocuments({ userId, date: { $gte: startOfWeek } });

    const favOutfitAgg = await WearHistory.aggregate([
      { $match: { userId } },
      { $group: { _id: '$outfitId', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const favoriteOutfitId = favOutfitAgg?.[0]?._id || null;
    const favoriteOutfit = favoriteOutfitId ? await Outfit.findById(favoriteOutfitId) : null;

    const favCategoryAgg = await WearHistory.aggregate([
      { $match: { userId } },
      { $lookup: { from: 'clothings', localField: 'clothingId', foreignField: '_id', as: 'cloth' } },
      { $unwind: '$cloth' },
      { $group: { _id: '$cloth.category', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const favoriteCategory = favCategoryAgg?.[0]?._id || null;

    const favColorAgg = await WearHistory.aggregate([
      { $match: { userId } },
      { $lookup: { from: 'clothings', localField: 'clothingId', foreignField: '_id', as: 'cloth' } },
      { $unwind: '$cloth' },
      { $group: { _id: '$cloth.color', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const favoriteColor = favColorAgg?.[0]?._id || null;

    res.status(200).json({
      success: true,
      data: {
        mostWorn,
        leastWorn,
        neverWorn,
        lastWorn,
        monthlyCount,
        weeklyCount,
        favoriteOutfit,
        favoriteCategory,
        favoriteColor,
      },
    });
  } catch (error) {
    next(error);
  }
};
