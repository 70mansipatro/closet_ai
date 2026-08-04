import test from 'node:test';
import assert from 'node:assert/strict';
import { buildOutfitRecommendation } from '../src/services/outfit.service.js';
import { createOutfitSchema } from '../src/validators/outfit.validator.js';

test('createOutfitSchema accepts empty optional outfit fields', () => {
  const { error, value } = createOutfitSchema.validate({
    occasion: 'casual',
    weather: 'sunny',
    temperature: 24,
    season: 'summer',
    top: '',
    bottom: '',
    footwear: '',
    outerwear: '',
    accessories: '',
    bag: '',
    watch: '',
  });

  assert.equal(error, undefined);
  assert.equal(value.outerwear, '');
  assert.equal(value.top, '');
});

test('buildOutfitRecommendation excludes dirty items and prefers fresh seasonal picks', () => {
  const wardrobe = [
    {
      _id: '1',
      category: 'top',
      color: 'blue',
      season: 'summer',
      laundryStatus: 'dirty',
      favorite: false,
      wearCount: 10,
      lastWorn: '2024-01-01T00:00:00.000Z',
      name: 'Blue shirt',
    },
    {
      _id: '2',
      category: 'top',
      color: 'white',
      season: 'summer',
      laundryStatus: 'clean',
      favorite: true,
      wearCount: 1,
      lastWorn: '2024-03-01T00:00:00.000Z',
      name: 'White tee',
    },
    {
      _id: '3',
      category: 'bottom',
      color: 'navy',
      season: 'summer',
      laundryStatus: 'clean',
      favorite: false,
      wearCount: 7,
      lastWorn: '2024-02-01T00:00:00.000Z',
      name: 'Navy trousers',
    },
    {
      _id: '4',
      category: 'bottom',
      color: 'black',
      season: 'summer',
      laundryStatus: 'clean',
      favorite: false,
      wearCount: 2,
      lastWorn: '2024-04-01T00:00:00.000Z',
      name: 'Black trousers',
    },
    {
      _id: '5',
      category: 'footwear',
      color: 'white',
      season: 'summer',
      laundryStatus: 'clean',
      favorite: false,
      wearCount: 4,
      lastWorn: '2024-04-15T00:00:00.000Z',
      name: 'White sneakers',
    },
    {
      _id: '6',
      category: 'outerwear',
      color: 'gray',
      season: 'summer',
      laundryStatus: 'clean',
      favorite: false,
      wearCount: 4,
      lastWorn: '2024-01-15T00:00:00.000Z',
      name: 'Gray blazer',
    },
  ];

  const result = buildOutfitRecommendation({
    wardrobe,
    request: { occasion: 'office', weather: 'sunny', temperature: 30, season: 'summer' },
  });

  assert.equal(result.top, 'White tee');
  assert.equal(result.bottom, 'Black trousers');
  assert.equal(result.footwear, 'White sneakers');
  assert.ok(result.recommendedItems.some((item) => item.name === 'White tee'));
  assert.ok(result.reason.includes('office'));
});

test('buildOutfitRecommendation uses only wardrobe items and returns Mongo IDs in recommendedItems', () => {
  const wardrobe = [
    { _id: 'top-1', category: 'top', name: 'White Shirt', color: 'white', season: 'summer', laundryStatus: 'clean', favorite: true, lastWorn: '2026-07-10T00:00:00.000Z' },
    { _id: 'bottom-1', category: 'bottom', name: 'Black Jeans', color: 'black', season: 'summer', laundryStatus: 'clean', favorite: false, lastWorn: '2026-07-08T00:00:00.000Z' },
    { _id: 'shoe-1', category: 'shoes', name: 'White Sneakers', color: 'white', season: 'summer', laundryStatus: 'clean', favorite: true, lastWorn: '2026-07-09T00:00:00.000Z' },
    { _id: 'accessory-1', category: 'accessory', name: 'Brown Belt', color: 'brown', season: 'all-season', laundryStatus: 'clean', favorite: true, lastWorn: '2026-07-01T00:00:00.000Z' },
    { _id: 'watch-1', category: 'other', subCategory: 'watch', name: 'Silver Watch', color: 'silver', season: 'all-season', laundryStatus: 'clean', favorite: true, lastWorn: '2026-06-20T00:00:00.000Z' },
    { _id: 'bag-1', category: 'other', subCategory: 'bag', name: 'Black Backpack', color: 'black', season: 'all-season', laundryStatus: 'clean', favorite: false, lastWorn: '2026-06-30T00:00:00.000Z' },
    { _id: 'dirty-1', category: 'top', name: 'Dirty Shirt', color: 'red', season: 'summer', laundryStatus: 'dirty', favorite: false, lastWorn: '2026-07-12T00:00:00.000Z' },
  ];

  const result = buildOutfitRecommendation({
    wardrobe,
    request: { occasion: 'office', weather: 'sunny', temperature: 30, season: 'summer' },
  });

  assert.equal(result.top, 'White Shirt');
  assert.equal(result.bottom, 'Black Jeans');
  assert.equal(result.footwear, 'White Sneakers');
  assert.equal(result.accessories, 'Brown Belt');
  assert.equal(result.watch, 'Silver Watch');
  assert.equal(result.bag, 'Black Backpack');
  assert.ok(result.recommendedItems.some((item) => item._id === 'top-1'));
  assert.ok(result.recommendedItems.some((item) => item._id === 'bottom-1'));
  assert.ok(result.recommendedItems.some((item) => item._id === 'shoe-1'));
  assert.ok(!result.recommendedItems.some((item) => item.name === 'Dirty Shirt'));
  assert.ok(!result.recommendedItems.some((item) => item.name === 'Classic top'));
});

test('buildOutfitRecommendation treats laundry statuses case-insensitively and ignores deleted items', () => {
  const wardrobe = [
    { _id: 'clean-top', category: 'top', name: 'White Shirt', color: 'white', season: 'summer', laundryStatus: 'CLEAN', favorite: true, lastWorn: '2026-07-10T00:00:00.000Z' },
    { _id: 'dirty-top', category: 'top', name: 'Dirty Shirt', color: 'red', season: 'summer', laundryStatus: 'DIRTY', favorite: false, lastWorn: '2026-07-12T00:00:00.000Z' },
    { _id: 'deleted-item', category: 'bottom', name: 'Deleted Jeans', color: 'black', season: 'summer', laundryStatus: 'Clean', favorite: false, lastWorn: '2026-07-08T00:00:00.000Z', isDeleted: true },
    { _id: 'bottom-1', category: 'bottom', name: 'Black Jeans', color: 'black', season: 'summer', laundryStatus: 'clean', favorite: false, lastWorn: '2026-07-08T00:00:00.000Z' },
    { _id: 'shoe-1', category: 'shoes', name: 'White Sneakers', color: 'white', season: 'summer', laundryStatus: 'clean', favorite: true, lastWorn: '2026-07-09T00:00:00.000Z' },
  ];

  const result = buildOutfitRecommendation({
    wardrobe,
    request: { occasion: 'casual', weather: 'sunny', temperature: 30, season: 'summer' },
  });

  assert.equal(result.top, 'White Shirt');
  assert.equal(result.bottom, 'Black Jeans');
  assert.equal(result.footwear, 'White Sneakers');
  assert.ok(result.recommendedItems.some((item) => item._id === 'clean-top'));
  assert.ok(!result.recommendedItems.some((item) => item._id === 'dirty-top'));
  assert.ok(!result.recommendedItems.some((item) => item._id === 'deleted-item'));
});
