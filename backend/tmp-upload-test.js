import fs from 'fs';
import path from 'path';

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
console.log('status', response.status);
const text = await response.text();
console.log(text);
