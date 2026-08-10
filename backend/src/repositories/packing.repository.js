import PackingList from '../models/PackingList.js';

export const createPackingItems = async ({ payload }) => PackingList.insertMany(payload);

export const findPackingForTrip = async ({ userId, tripId }) =>
  PackingList.find({ userId, tripId }).sort({ required: -1, category: 1, createdAt: 1 });

export const findPackingItemById = async ({ userId, tripId, id }) =>
  PackingList.findOne({ _id: id, userId, tripId });

export const updatePackingItem = async ({ userId, tripId, id, updateData }) =>
  PackingList.findOneAndUpdate({ _id: id, userId, tripId }, { $set: updateData }, { new: true });

export const deletePackingItem = async ({ userId, tripId, id }) =>
  PackingList.findOneAndDelete({ _id: id, userId, tripId });

export const deletePackingForTrip = async ({ userId, tripId }) =>
  PackingList.deleteMany({ userId, tripId });
