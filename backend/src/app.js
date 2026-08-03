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

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) {
      callback(null, true);
      return;
    }

    try {
      const { protocol, hostname } = new URL(origin);
      const isLocalhost = ['localhost', '127.0.0.1'].includes(hostname);
      if (isLocalhost && ['http:', 'https:'].includes(protocol)) {
        callback(null, true);
        return;
      }
    } catch (error) {
      console.warn(`[CORS] Invalid origin received: ${origin}`);
    }

    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use((req, res, next) => {
  console.log('[REQUEST]', req.method, req.originalUrl, { origin: req.headers.origin || null });

  if (req.method === 'OPTIONS') {
    console.log(`[CORS] OPTIONS request received for ${req.originalUrl}`);
    res.setHeader('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Vary', 'Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
    console.log(`[CORS] Returning preflight headers for ${req.originalUrl}`);
    return res.sendStatus(204);
  }

  if (req.method === 'POST' && req.path === '/api/auth/register') {
    console.log(`[AUTH] Register request received for ${req.originalUrl}`);
  }

  next();
});

app.use(cors(corsOptions));
app.options(/\/api\/(.*)/, cors(corsOptions), (_req, res) => {
  res.sendStatus(204);
});

app.use((req, res, next) => {
  res.on('finish', () => {
    if (req.method === 'OPTIONS' || req.path === '/api/auth/register') {
      console.log(`[CORS] headers returned for ${req.method} ${req.originalUrl}`, {
        allowOrigin: res.getHeader('Access-Control-Allow-Origin'),
        allowMethods: res.getHeader('Access-Control-Allow-Methods'),
        allowHeaders: res.getHeader('Access-Control-Allow-Headers'),
        allowCredentials: res.getHeader('Access-Control-Allow-Credentials'),
      });
    }
  });

  next();
});

app.use(helmet());
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
