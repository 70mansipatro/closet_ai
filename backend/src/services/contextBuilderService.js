import Clothing from '../models/Clothing.js';
import Outfit from '../models/Outfit.js';
import Trip from '../models/Trip.js';
import WearHistory from '../models/WearHistory.js';
import { getWeather } from './weather.service.js';

const cleanLaundryStatus = (value) => String(value || '').trim().toLowerCase();

const isReadyToWear = (item) => {
  const status = cleanLaundryStatus(item?.laundryStatus);
  return status === 'clean' || status === 'ready';
};

export const buildChatContext = ({ userId, message, recentMessages = [], wardrobe = [], laundry = [], wearHistory = [], calendar = [], trips = [] }) => {
  const normalizedWardrobe = (wardrobe || [])
    .filter((item) => item && item._id)
    .filter(isReadyToWear)
    .map((item) => ({
      _id: String(item._id),
      category: item.category,
      subCategory: item.subCategory,
      color: item.color,
      material: item.fabric || item.material,
      season: item.season,
      occasion: item.occasion,
      size: item.size,
      laundryStatus: item.laundryStatus,
      lastWorn: item.lastWorn,
      wearCount: item.wearCount || 0,
    }));

  const normalizedLaundry = (laundry || []).map((entry) => ({
    clothingId: entry?.clothingId ? String(entry.clothingId) : null,
    status: entry?.status || entry?.laundryStatus || 'unknown',
  }));

  const normalizedWearHistory = (wearHistory || []).slice(0, 8).map((entry) => ({
    clothingId: entry?.clothingId ? String(entry.clothingId) : null,
    date: entry?.date,
    occasion: entry?.occasion,
  }));

  const normalizedCalendar = (calendar || []).slice(0, 6).map((entry) => ({
    date: entry?.date,
    outfitId: entry?.outfitId ? String(entry.outfitId) : null,
    notes: entry?.notes,
  }));

  const normalizedTrips = (trips || []).slice(0, 5).map((trip) => ({
    _id: trip?._id ? String(trip._id) : null,
    destination: trip?.destination,
    startDate: trip?.startDate,
    endDate: trip?.endDate,
    activities: trip?.activities || [],
  }));

  const context = {
    wardrobe: normalizedWardrobe,
    laundry: normalizedLaundry,
    wearHistory: normalizedWearHistory,
    calendar: normalizedCalendar,
    trips: normalizedTrips,
    recentMessages: recentMessages.slice(-6),
    message,
  };

  return context;
};

export const buildContextForUser = async ({ userId, message, recentMessages = [] }) => {
  const [wardrobeItems, laundryItems, wearHistoryItems, calendarItems, tripItems] = await Promise.all([
    Clothing.find({ userId }).lean().sort({ updatedAt: -1 }).limit(80),
    [] ,
    WearHistory.find({ userId }).lean().sort({ date: -1 }).limit(20),
    [],
    Trip.find({ owner: userId }).lean().sort({ startDate: 1 }).limit(20),
  ]);

  return buildChatContext({
    userId,
    message,
    recentMessages,
    wardrobe: wardrobeItems,
    laundry: laundryItems,
    wearHistory: wearHistoryItems,
    calendar: calendarItems,
    trips: tripItems,
  });
};
