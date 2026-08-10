import test from 'node:test';
import assert from 'assert';
import fs from 'fs';
import path from 'path';

test('routes files exist', () => {
  const routeFiles = [
    'calendar.routes.js',
    'history.routes.js',
    'outfit.routes.js',
    'laundry.routes.js',
    'trip.routes.js',
    'weather.routes.js',
  ];
  const routesDir = path.resolve('./src/routes');
  for (const file of routeFiles) {
    const exists = fs.existsSync(path.join(routesDir, file));
    assert.ok(exists, `${file} should exist in src/routes`);
  }
});
