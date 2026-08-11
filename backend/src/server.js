import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const envPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../.env');
dotenv.config({ path: envPath });

console.log('dotenv config loaded from:', envPath);
console.log('Mongo URI exists in server:', !!process.env.MONGODB_URI);
console.log('Gemini API key loaded:', !!process.env.GEMINI_API_KEY);
console.log('Gemini model configured:', process.env.GEMINI_MODEL || 'gemini-2.0-flash');
console.log('Cloudinary credentials available in server:', {
  cloudName: !!process.env.CLOUDINARY_CLOUD_NAME,
  apiKey: !!process.env.CLOUDINARY_API_KEY,
  apiSecret: !!process.env.CLOUDINARY_API_SECRET,
});

const { default: app } = await import('./app.js');
const { connectDatabase } = await import('./config/database.js');
const { bootstrapSubscriptionPlans } = await import('./services/subscriptionService.js');
const { startNotificationScheduler } = await import('./services/notificationScheduler.js');

const port = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await connectDatabase();
    await bootstrapSubscriptionPlans();
    startNotificationScheduler();

    app.listen(port, '0.0.0.0', () => {
      console.log(`ClosetAI backend listening on http://localhost:${port}`);
    });
  } catch (error) {
    console.error('Failed to initialize server:', error);
    process.exit(1);
  }
};

startServer();
