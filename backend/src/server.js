import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const envPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../.env');
dotenv.config({ path: envPath });

console.log('dotenv config loaded from:', envPath);
console.log('Mongo URI exists in server:', !!process.env.MONGODB_URI);

const { default: app } = await import('./app.js');
const { connectDatabase } = await import('./config/database.js');

const port = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await connectDatabase();

    app.listen(port, '0.0.0.0', () => {
      console.log(`ClosetAI backend listening on http://localhost:${port}`);
    });
  } catch (error) {
    console.error('Failed to initialize server:', error);
    process.exit(1);
  }
};

startServer();
