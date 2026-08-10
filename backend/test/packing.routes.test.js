import test from 'node:test';
import assert from 'assert';
import tripRoutes from '../src/routes/trip.routes.js';

const getRoutePaths = (router) =>
  (router.stack || [])
    .filter((layer) => layer?.route)
    .map((layer) => ({
      path: layer.route.path,
      methods: Object.keys(layer.route.methods).sort().join(',').toUpperCase(),
    }));

test('trip routes include packing endpoints', () => {
  const routes = getRoutePaths(tripRoutes);
  const paths = routes.map((route) => route.path);

  assert.ok(
    paths.includes('/:id/packing/generate'),
    'Expected trip routes to include /:id/packing/generate',
  );
  assert.ok(
    paths.includes('/:id/packing'),
    'Expected trip routes to include /:id/packing',
  );
  assert.ok(
    paths.includes('/:id/packing/:itemId/toggle'),
    'Expected trip routes to include /:id/packing/:itemId/toggle',
  );
  assert.ok(
    paths.includes('/:id/packing/add'),
    'Expected trip routes to include /:id/packing/add',
  );
});
