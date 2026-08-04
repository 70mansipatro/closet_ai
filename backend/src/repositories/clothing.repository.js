import Clothing from '../models/Clothing.js';

export const createClothingItem = async (payload) => Clothing.create(payload);

export const findClothingItems = async ({
  userId,
  page = 1,
  limit = 20,
  search,
  category,
  color,
  brand,
  season,
  occasion,
  laundryStatus,
  favorite,
  sortBy = 'createdAt',
  sortOrder = 'desc',
}) => {
  const query = { userId };

  if (search) {
    query.$or = [
      { category: { $regex: search, $options: 'i' } },
      { subCategory: { $regex: search, $options: 'i' } },
      { color: { $regex: search, $options: 'i' } },
      { brand: { $regex: search, $options: 'i' } },
      { season: { $regex: search, $options: 'i' } },
      { occasion: { $regex: search, $options: 'i' } },
      { notes: { $regex: search, $options: 'i' } },
    ];
  }

  if (category) query.category = category;
  if (color) query.color = { $regex: color, $options: 'i' };
  if (brand) query.brand = { $regex: brand, $options: 'i' };
  if (season) query.season = season;
  if (occasion) query.occasion = { $regex: occasion, $options: 'i' };
  if (laundryStatus) query.laundryStatus = laundryStatus;
  if (favorite !== undefined) query.favorite = favorite === 'true' || favorite === true;

  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const skip = (safePage - 1) * safeLimit;
  const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

  const [items, totalItems] = await Promise.all([
    Clothing.find(query).sort(sort).skip(skip).limit(safeLimit),
    Clothing.countDocuments(query),
  ]);

  const totalPages = Math.max(Math.ceil(totalItems / safeLimit), 1);

  return {
    items,
    pagination: {
      page: safePage,
      limit: safeLimit,
      totalItems,
      totalPages,
      hasMore: safePage < totalPages,
    },
  };
};

export const findClothingById = async ({ userId, id }) => Clothing.findOne({ _id: id, userId });

export const updateClothingItem = async ({ userId, id, updateData }) => {
  const clothing = await Clothing.findOne({ _id: id, userId });
  if (!clothing) return null;

  Object.assign(clothing, updateData);
  await clothing.save();
  return clothing;
};

export const deleteClothingItem = async ({ userId, id }) => {
  const clothing = await Clothing.findOne({ _id: id, userId });
  if (!clothing) return null;

  await clothing.deleteOne();
  return clothing;
};
