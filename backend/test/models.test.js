import test from 'node:test';
import assert from 'assert';

import Clothing from '../src/models/Clothing.js';
import OutfitCalendar from '../src/models/OutfitCalendar.js';
import WearHistory from '../src/models/WearHistory.js';
import Outfit from '../src/models/Outfit.js';

test('models are defined', () => {
  assert.ok(Clothing, 'Clothing model should be defined');
  assert.ok(OutfitCalendar, 'OutfitCalendar model should be defined');
  assert.ok(WearHistory, 'WearHistory model should be defined');
  assert.ok(Outfit, 'Outfit model should be defined');
});
