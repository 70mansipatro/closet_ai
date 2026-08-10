import Trip from '../models/Trip.js';

export const createTrip = async ({ payload }) => Trip.create(payload);

export const findTripsForUser = async ({
  userId,
  search,
  status,
  sortBy = 'startDate',
  sortOrder = 'asc',
  page = 1,
  limit = 50,
}) => {
  const query = { owner: userId };
  const now = new Date();

  if (search) {
    const regex = new RegExp(String(search).trim(), 'i');
    query.$or = [
      { tripName: regex },
      { destination: regex },
      { city: regex },
      { country: regex },
      { activities: regex },
    ];
  }

  if (status === 'upcoming') {
    query.startDate = { $gt: now };
  } else if (status === 'ongoing') {
    query.startDate = { $lte: now };
    query.endDate = { $gte: now };
  } else if (status === 'completed') {
    query.endDate = { $lt: now };
  }

  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const safePage = Math.max(Number(page) || 1, 1);
  const skip = (safePage - 1) * safeLimit;
  const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

  const [items, totalItems] = await Promise.all([
    Trip.find(query).sort(sort).skip(skip).limit(safeLimit),
    Trip.countDocuments(query),
  ]);

  return {
    items,
    pagination: {
      page: safePage,
      limit: safeLimit,
      totalItems,
      totalPages: Math.max(Math.ceil(totalItems / safeLimit), 1),
      hasMore: safePage * safeLimit < totalItems,
    },
  };
};

export const findTripById = async ({ userId, id }) => Trip.findOne({ _id: id, owner: userId });

export const updateTrip = async ({ userId, id, updateData }) =>
  Trip.findOneAndUpdate({ _id: id, owner: userId }, { $set: updateData }, { new: true });

export const deleteTrip = async ({ userId, id }) =>
  Trip.findOneAndDelete({ _id: id, owner: userId });
