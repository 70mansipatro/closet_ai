import Trip from '../models/Trip.js';
import { createTripSchema, updateTripSchema } from '../validators/trip.validator.js';

export const createTrip = async (req, res, next) => {
  try {
    const { error, value } = createTripSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const trip = await Trip.create({ ...value, owner: req.user._id });
    res.status(201).json(trip);
  } catch (error) {
    next(error);
  }
};

export const listTrips = async (req, res, next) => {
  try {
    const trips = await Trip.find({ owner: req.user._id }).sort({ startDate: 1 });
    res.json(trips);
  } catch (error) {
    next(error);
  }
};

export const getTrip = async (req, res, next) => {
  try {
    const trip = await Trip.findOne({ _id: req.params.id, owner: req.user._id });
    if (!trip) return res.status(404).json({ message: 'Trip not found' });
    res.json(trip);
  } catch (error) {
    next(error);
  }
};

export const updateTrip = async (req, res, next) => {
  try {
    const { error, value } = updateTripSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const trip = await Trip.findOne({ _id: req.params.id, owner: req.user._id });
    if (!trip) return res.status(404).json({ message: 'Trip not found' });

    Object.assign(trip, value);
    await trip.save();
    res.json(trip);
  } catch (error) {
    next(error);
  }
};

export const deleteTrip = async (req, res, next) => {
  try {
    const trip = await Trip.findOne({ _id: req.params.id, owner: req.user._id });
    if (!trip) return res.status(404).json({ message: 'Trip not found' });

    await trip.deleteOne();
    res.json({ message: 'Trip deleted successfully' });
  } catch (error) {
    next(error);
  }
};

export const addPackingItem = async (req, res, next) => {
  try {
    const trip = await Trip.findOne({ _id: req.params.id, owner: req.user._id });
    if (!trip) return res.status(404).json({ message: 'Trip not found' });

    trip.packingList.push({ item: req.body.item, packed: false, category: req.body.category || 'other' });
    await trip.save();
    res.status(201).json(trip.packingList);
  } catch (error) {
    next(error);
  }
};

export const updatePackingItem = async (req, res, next) => {
  try {
    const trip = await Trip.findOne({ _id: req.params.id, owner: req.user._id });
    if (!trip) return res.status(404).json({ message: 'Trip not found' });

    const item = trip.packingList.id(req.params.itemId);
    if (!item) return res.status(404).json({ message: 'Packing list item not found' });

    item.packed = req.body.packed ?? item.packed;
    item.item = req.body.item ?? item.item;
    item.category = req.body.category ?? item.category;
    await trip.save();
    res.json(item);
  } catch (error) {
    next(error);
  }
};

export const deletePackingItem = async (req, res, next) => {
  try {
    const trip = await Trip.findOne({ _id: req.params.id, owner: req.user._id });
    if (!trip) return res.status(404).json({ message: 'Trip not found' });

    trip.packingList.id(req.params.itemId)?.deleteOne();
    await trip.save();
    res.json({ message: 'Packing item deleted successfully' });
  } catch (error) {
    next(error);
  }
};
