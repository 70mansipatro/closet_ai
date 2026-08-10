import test from 'node:test';
import assert from 'node:assert/strict';
import { createTripSchema, updateTripSchema } from '../src/validators/trip.validator.js';

test('createTripSchema validates required trip fields and date order', () => {
  const { error, value } = createTripSchema.validate({
    tripName: 'Business trip',
    destination: 'Paris',
    country: 'France',
    city: 'Paris',
    startDate: '2026-09-15',
    endDate: '2026-09-20',
    activities: ['meeting', 'dining'],
    notes: 'Pack formal wear',
  });

  assert.equal(error, undefined);
  assert.equal(value.tripName, 'Business trip');
  assert.equal(value.destination, 'Paris');
  assert.equal(value.city, 'Paris');
  assert.ok(value.activities.includes('meeting'));
});

test('createTripSchema rejects endDate before startDate', () => {
  const { error } = createTripSchema.validate({
    tripName: 'Bad dates',
    destination: 'Tokyo',
    country: 'Japan',
    city: 'Tokyo',
    startDate: '2026-10-10',
    endDate: '2026-10-05',
  });

  assert.ok(error);
  assert.ok(error.message.includes('endDate must be the same or after startDate'));
});

test('updateTripSchema requires at least one field and allows partial updates', () => {
  const { error, value } = updateTripSchema.validate({
    destination: 'Berlin',
  });

  assert.equal(error, undefined);
  assert.equal(value.destination, 'Berlin');
});

test('updateTripSchema rejects empty payloads', () => {
  const { error } = updateTripSchema.validate({});
  assert.ok(error);
});
