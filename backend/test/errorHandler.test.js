import test from 'node:test';
import assert from 'node:assert/strict';
import { errorHandler } from '../src/middleware/errorHandler.js';
import { AppError } from '../src/utils/appError.js';

test('returns the AppError status code for validation and conflict errors', () => {
  let statusCode = 0;
  let payload = null;
  const req = { method: 'POST', originalUrl: '/api/auth/register' };
  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(data) {
      payload = data;
      return this;
    },
  };

  const err = new AppError('Email already registered', 409);
  errorHandler(err, req, res, () => {});

  assert.equal(statusCode, 409);
  assert.equal(payload.message, 'Email already registered');
});

test('returns a structured error payload with success, error, and stack details', () => {
  let statusCode = 0;
  let payload = null;
  const req = { method: 'POST', originalUrl: '/api/auth/register' };
  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(data) {
      payload = data;
      return this;
    },
  };

  const err = new AppError('Registration failed', 500);
  errorHandler(err, req, res, () => {});

  assert.equal(statusCode, 500);
  assert.equal(payload.success, false);
  assert.equal(payload.message, 'Registration failed');
  assert.equal(payload.error, 'AppError');
  assert.match(payload.stack, /Registration failed/);
});
