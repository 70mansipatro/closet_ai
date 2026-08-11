import test from 'node:test';
import assert from 'node:assert/strict';
import { buildDefaultSubscriptionPlans } from '../src/services/subscriptionService.js';

test('buildDefaultSubscriptionPlans includes free and premium plans', () => {
  const plans = buildDefaultSubscriptionPlans();
  const codes = plans.map((plan) => plan.planCode);

  assert.ok(codes.includes('free'));
  assert.ok(codes.includes('premium_monthly'));
  assert.ok(codes.includes('premium_yearly'));
});
