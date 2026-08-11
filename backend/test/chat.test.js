import test from 'node:test';
import assert from 'node:assert/strict';

import { detectIntent } from '../src/services/chatService.js';
import { buildChatContext } from '../src/services/contextBuilderService.js';

test('detectIntent classifies outfit requests', () => {
  assert.equal(detectIntent('What should I wear today?'), 'OUTFIT_RECOMMENDATION');
  assert.equal(detectIntent('What clothes are dirty?'), 'LAUNDRY');
  assert.equal(detectIntent('What did I wear yesterday?'), 'WEAR_HISTORY');
});

test('buildChatContext excludes dirty items and includes recent wear data', () => {
  const wardrobe = [
    { _id: '1', category: 'top', subCategory: 'shirt', color: 'blue', material: 'cotton', season: 'summer', occasion: 'casual', size: 'M', laundryStatus: 'clean', lastWorn: '2025-01-01T00:00:00.000Z', wearCount: 2 },
    { _id: '2', category: 'top', subCategory: 'shirt', color: 'red', material: 'cotton', season: 'summer', occasion: 'casual', size: 'M', laundryStatus: 'dirty', lastWorn: '2025-01-02T00:00:00.000Z', wearCount: 9 },
  ];

  const context = buildChatContext({ wardrobe, laundry: [{ clothingId: '2', status: 'dirty' }], wearHistory: [{ clothingId: '1', date: '2025-01-01', occasion: 'casual' }] });

  assert.equal(context.wardrobe.length, 1);
  assert.equal(context.wardrobe[0]._id, '1');
  assert.equal(context.laundry[0].status, 'dirty');
  assert.equal(context.wearHistory.length, 1);
});
