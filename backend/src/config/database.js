import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import mongoose from 'mongoose';

const envPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../.env');
dotenv.config({ path: envPath });

let connectionPromise = null;

export const isDatabaseConnected = () => mongoose.connection.readyState === 1;

export const connectDatabase = async () => {
  if (mongoose.connection.readyState === 1) {
    return true;
  }

  if (connectionPromise) {
    return connectionPromise;
  }

  const mongoURI = process.env.MONGODB_URI;

  console.log('dotenv config loaded from:', envPath);
  console.log('Mongo URI exists:', !!mongoURI);
  console.log('Mongo URI Host:', mongoURI?.replace(/\/\/([^:@]+):([^@]+)@/, '//***:***@'));

  if (!mongoURI) {
    throw new Error('MONGODB_URI is missing in .env; cannot connect to MongoDB Atlas');
  }

  mongoose.set('strictQuery', true);

  connectionPromise = mongoose
    .connect(mongoURI, {
      autoIndex: false,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      family: 4,
    })
    .then(() => {
      console.log('✅ MongoDB Connected');
      return true;
    })
    .catch((error) => {
      console.error('========== MONGODB ERROR ==========');
      console.error(error);
      console.error(error?.stack);
      console.error('==================================');
      throw error;
    })
    .finally(() => {
      connectionPromise = null;
    });

  return connectionPromise;
};
