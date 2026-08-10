import OutfitCalendar from '../models/OutfitCalendar.js';

export const createCalendarEntry = async ({ payload }) => OutfitCalendar.create(payload);

export const findCalendarForUser = async ({ userId, startDate, endDate }) => {
  const query = { userId };
  if (startDate && endDate) query.date = { $gte: startDate, $lte: endDate };
  return OutfitCalendar.find(query).sort({ date: 1 });
};

export const findCalendarByDate = async ({ userId, date }) => OutfitCalendar.findOne({ userId, date });

export const findCalendarById = async ({ userId, id }) => OutfitCalendar.findOne({ _id: id, userId });

export const updateCalendarEntry = async ({ userId, id, updateData }) =>
  OutfitCalendar.findOneAndUpdate({ _id: id, userId }, updateData, { new: true, runValidators: true });

export const deleteCalendarEntry = async ({ userId, id }) => OutfitCalendar.findOneAndDelete({ _id: id, userId });
