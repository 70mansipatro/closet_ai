import test from 'node:test';
import assert from 'node:assert/strict';
import { buildClothingPayload, parseJsonFromText, validateAnalysisConfig } from '../src/services/clothing.service.js';

test('buildClothingPayload normalizes and defaults wardrobe fields', async () => {
  const payload = await buildClothingPayload({
    payload: {
      category: 'top',
      favorite: 'true',
      purchasePrice: '49.99',
      wearCount: '3',
      lastWorn: '2026-08-01',
    },
    userId: '64d2f5f10d4f5c9c8e4f8a12',
    aiAnalysis: { category: 'dress', season: 'summer' },
  });

  assert.equal(payload.category, 'top');
  assert.equal(payload.favorite, true);
  assert.equal(payload.purchasePrice, 49.99);
  assert.equal(payload.season, 'summer');
  // wearCount/lastWorn are backend-owned (see services/wear.service.js) and
  // must never be settable through create/update — even if a client tries.
  assert.equal(payload.wearCount, undefined);
  assert.equal(payload.lastWorn, undefined);
});

test('parseJsonFromText extracts JSON from markdown-wrapped Gemini output', () => {
  const parsed = parseJsonFromText('```json\n{"category":"top","subCategory":"tee"}\n```');

  assert.deepEqual(parsed, { category: 'top', subCategory: 'tee' });
});

test('validateAnalysisConfig reports all missing environment variables', () => {
  const config = validateAnalysisConfig({
    GEMINI_API_KEY: '',
    CLOUDINARY_CLOUD_NAME: '',
    CLOUDINARY_API_KEY: '',
    CLOUDINARY_API_SECRET: '',
    JWT_SECRET: '',
  });

  assert.deepEqual(config.missing, [
    'GEMINI_API_KEY',
    'CLOUDINARY_CLOUD_NAME',
    'CLOUDINARY_API_KEY',
    'CLOUDINARY_API_SECRET',
    'JWT_SECRET',
  ]);
});
