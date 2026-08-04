import fs from 'fs';
import path from 'path';
import test from 'node:test';
import assert from 'node:assert/strict';

const checkServerAvailability = async () => {
  try {
    const response = await fetch('http://localhost:3000/api/health', { method: 'GET' });
    return response.ok || response.status === 503;
  } catch {
    return false;
  }
};

test('tmp upload smoke test', async () => {
  const isServerAvailable = await checkServerAvailability();

  if (!isServerAvailable) {
    test.skip('Backend server not running on localhost:3000; skipping upload smoke test');
    return;
  }

  const filePath = path.resolve('../web/favicon.png');
  const fileBuffer = fs.readFileSync(filePath);
  const boundary = '----ClosetAI-test-boundary';
  const body = [
    `--${boundary}\r\n`,
    'Content-Disposition: form-data; name="image"; filename="favicon.png"\r\n',
    'Content-Type: image/png\r\n',
    '\r\n',
    fileBuffer,
    `\r\n--${boundary}--\r\n`,
  ].join('');

  const url = 'http://localhost:3000/api/ai/analyze';
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer test',
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
    },
    body,
  });

  const text = await response.text();
  console.log('status', response.status);
  console.log(text);

  assert.ok(response.status >= 200 && response.status < 500, `Expected an HTTP response, received ${response.status}`);
});
