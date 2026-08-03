import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

import authRoutes from './routes/auth.routes.js';
import { swaggerDefinition } from './docs/swagger.js';
import clothingRoutes from './routes/clothing.routes.js';
import outfitRoutes from './routes/outfit.routes.js';
import tripRoutes from './routes/trip.routes.js';
import { errorHandler } from './middleware/errorHandler.js';
import { isDatabaseConnected } from './config/database.js';

const app = express();

app.use(helmet());
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  preflightContinue: false,
  optionsSuccessStatus: 204,
}));
app.use(compression());
app.use(morgan('dev'));
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

const swaggerSpec = swaggerJsdoc({
  definition: swaggerDefinition,
  apis: ['./src/routes/*.js'],
});

app.use('/api', (req, res, next) => {
  if (req.path === '/health' || req.path === '/docs' || req.path.startsWith('/docs/')) {
    return next();
  }

  if (isDatabaseConnected()) {
    return next();
  }

  res.status(503).json({
    status: 'degraded',
    service: 'closetai-backend',
    message: 'Database unavailable; the server is running in degraded mode.',
  });
});

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'closetai-backend',
    database: isDatabaseConnected() ? 'connected' : 'unavailable',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/clothing', clothingRoutes);
app.use('/api/outfits', outfitRoutes);
app.use('/api/trips', tripRoutes);

app.use(errorHandler);

export default app;
