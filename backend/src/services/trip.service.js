import Clothing from '../models/Clothing.js';
import Outfit from '../models/Outfit.js';
import Trip from '../models/Trip.js';
import { getWeather } from './weather.service.js';
import { buildOutfitRecommendation, generateOutfitRecommendation } from './outfit.service.js';

const normalizeLaundryStatus = (value) => (value ?? '').toString().trim().toLowerCase();
const UNAVAILABLE_LAUNDRY_STATUSES = new Set(['dirty', 'washing', 'drying', 'ironing', 'in-use', 'repair']);

const isCleanAndReady = (item) => {
  const status = normalizeLaundryStatus(item?.laundryStatus);
  return status === 'clean' || status === 'ready';
};

const buildDayRequests = (trip, weather, activities) => {
  const days = [];
  let date = new Date(trip.startDate);
  const endDate = new Date(trip.endDate);
  let index = 0;

  while (date <= endDate) {
    const forecast = weather.forecast.find((entry) => entry.date.slice(0, 10) === date.toISOString().slice(0, 10));
    days.push({
      date: new Date(date),
      activity: activities[index] || 'Travel',
      weather: forecast?.condition || 'Unknown',
      temperature: forecast?.temperature ?? 20,
      season: 'all-season',
    });
    date.setDate(date.getDate() + 1);
    index += 1;
  }

  return days;
};

export const generateTripOutfits = async ({ userId, tripId }) => {
  const trip = await Trip.findOne({ _id: tripId, owner: userId });
  if (!trip) {
    throw new Error('Trip not found');
  }

  const wardrobe = await Clothing.find({
    userId,
    isDeleted: { $ne: true },
    deleted: { $ne: true },
    deletedAt: { $exists: false },
  }).lean();

  const cleanWardrobe = wardrobe.filter(isCleanAndReady);
  const weather = await getWeather({ city: trip.city || trip.destination, country: trip.country, startDate: trip.startDate, endDate: trip.endDate });

  const days = buildDayRequests(trip, weather, trip.activities || []);

  const results = [];
  for (const day of days) {
    const request = {
      occasion: day.activity,
      weather: day.weather,
      temperature: day.temperature,
      season: day.season,
    };

    const recommendation = await generateOutfitRecommendation({ wardrobe: cleanWardrobe, request });

    const saved = await Outfit.create({
      userId,
      occasion: day.activity,
      weather: day.weather,
      temperature: day.temperature,
      recommendedItems: recommendation.recommendedItems || [],
      top: recommendation.top ?? '',
      bottom: recommendation.bottom ?? '',
      footwear: recommendation.footwear ?? '',
      outerwear: recommendation.outerwear ?? '',
      accessories: recommendation.accessories ?? '',
      bag: recommendation.bag ?? '',
      watch: recommendation.watch ?? '',
      confidenceScore: recommendation.confidence || 0,
      reason: recommendation.reason || '',
    });

    results.push({
      date: day.date,
      activity: day.activity,
      outfit: saved,
      reason: recommendation.reason,
    });
  }

  return { tripId, days: results, weatherSummary: weather.weatherSummary || '', averageTemperature: weather.forecast.reduce((sum, entry) => sum + (entry.temperature || 0), 0) / Math.max(1, weather.forecast.length) };
};
