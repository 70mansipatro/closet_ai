import { AppError } from '../utils/appError.js';
import { findClothingById, incrementWearCount } from '../repositories/clothing.repository.js';
import { createWearHistory } from '../repositories/history.repository.js';
import { changeLaundryStatus } from './laundry.service.js';

// Single source of truth for "wearing" a clothing item: bumps wearCount +
// lastWorn atomically, flips laundryStatus clean -> dirty via the existing
// laundry state machine, and writes a WearHistory row. Every wear path in
// the app (Wardrobe "Mark as Worn", AI "Wear This Outfit", Outfit Calendar
// "Wear Today") funnels through this so Analytics is always fed consistently.
const runWearTransaction = async ({ userId, clothingId, occasion, weather, rating, notes, outfitId, wornAt }) => {
  const existing = await findClothingById({ userId, id: clothingId });
  if (!existing) {
    throw new AppError('Clothing item not found', 404);
  }

  const now = wornAt || new Date();
  const clothing = await incrementWearCount({ userId, id: clothingId, wornAt: now });

  if ((existing.laundryStatus || 'clean').toString().trim().toLowerCase() === 'clean') {
    try {
      await changeLaundryStatus({ userId, clothingId, newStatus: 'dirty', method: 'worn' });
    } catch (error) {
      console.error('[WEAR] failed to flip laundry status to dirty', { userId, clothingId, error: error.message });
    }
  }

  const wearHistory = await createWearHistory({
    payload: {
      userId,
      clothingId,
      outfitId: outfitId || undefined,
      date: now,
      occasion: occasion || '',
      weather: weather || '',
      rating: rating ?? undefined,
      notes: notes || '',
    },
  });

  return { clothing, wearHistory };
};

export const markClothingWorn = async ({ userId, clothingId, occasion, weather, rating, notes, outfitId, wornAt }) =>
  runWearTransaction({ userId, clothingId, occasion, weather, rating, notes, outfitId, wornAt });

export const markManyClothingWorn = async ({ userId, clothingIds, outfitId, occasion, weather, wornAt }) => {
  const now = wornAt || new Date();
  const results = [];
  for (const clothingId of clothingIds || []) {
    try {
      const result = await runWearTransaction({ userId, clothingId, occasion, weather, outfitId, wornAt: now });
      results.push(result);
    } catch (error) {
      console.error('[WEAR] failed to mark clothing item as worn', { userId, clothingId, error: error.message });
    }
  }
  return results;
};
