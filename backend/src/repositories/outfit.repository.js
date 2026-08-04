import Outfit from '../models/Outfit.js';

export const createOutfitRecord = async ({ payload }) => Outfit.create(payload);

export const findOutfitsForUser = async ({ userId, favorite, search }) => {
  const filter = { userId };
  if (typeof favorite === 'boolean') filter.favorite = favorite;
  if (search) filter.$or = [
    { occasion: new RegExp(search, 'i') },
    { reason: new RegExp(search, 'i') },
    { top: new RegExp(search, 'i') },
    { bottom: new RegExp(search, 'i') },
  ];

  return Outfit.find(filter).sort({ createdAt: -1 });
};

export const findOutfitById = async ({ userId, id }) => Outfit.findOne({ _id: id, userId });

export const updateOutfitRecord = async ({ userId, id, updateData }) =>
  Outfit.findOneAndUpdate({ _id: id, userId }, updateData, { new: true, runValidators: true });

export const deleteOutfitRecord = async ({ userId, id }) => Outfit.findOneAndDelete({ _id: id, userId });
