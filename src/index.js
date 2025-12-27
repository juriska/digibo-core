const express = require('express');
const cors = require('cors');
const { createPool } = require('./config/database');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
require('dotenv').config();
const app = express();

// CORS configuration
const corsOptions = {
  origin: ['https://preview--digi-backstage-haven.lovable.app', 'http://localhost:3000', 'http://localhost:5173'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};

app.use(cors(corsOptions));
app.use(express.json());

// Enable strict routing to avoid trailing slash issues
app.set('strict routing', false);

const port = process.env.PORT || 3000;
const mockEnabled = process.env.MOCK_ENABLED === 'true';

// Import routes
const ffoRoutes = require('./routes/ffo.routes');
const paymentRoutes = require('./routes/payments.routes');
const bodiRoutes = require('./routes/bodi.routes');
const appRoutes = require('./routes/app.routes');
const documentsRoutes = require('./routes/documents.routes');
const customerRoutes = require('./routes/customer.routes');
const auditlogRoutes = require('./routes/auditlog.routes');

async function init() {
  try {
    if (!mockEnabled) {
      console.log('Initializing database connection...');
      await createPool();
      console.log('Database connection initialized successfully');
    }

    // Register routes
    app.use('/api/ffo', ffoRoutes);
    app.use('/api/payments', paymentRoutes);
    app.use('/api/documents', documentsRoutes);
    app.use('/api/customer', customerRoutes);
    app.use('/api/auditlog', auditlogRoutes);
    app.use('/bodi', bodiRoutes);
    app.use('/api/app', appRoutes);

    app.get('/', (req, res) => {
      res.send('✅ API Gateway is up and running');
    });

    // 404 handler (must be after all routes)
    app.use(notFoundHandler);

    // Global error handler (must be last)
    app.use(errorHandler);

    app.listen(port, () => {
      console.log(`API Gateway listening on port ${port}`);
      console.log(`Mock mode: ${mockEnabled ? 'ENABLED' : 'DISABLED'}`);
    });
  } catch (error) {
    console.error('Failed to initialize application:', error);
    process.exit(1);
  }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('[PROCESS] Unhandled Promise Rejection:');
  console.error('[PROCESS] Reason:', reason);
  console.error('[PROCESS] Promise:', promise);
  // Don't exit the process, just log the error
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('[PROCESS] Uncaught Exception:');
  console.error('[PROCESS] Error:', error.message);
  console.error('[PROCESS] Stack:', error.stack);
  // Don't exit the process for most errors
  if (error.code === 'EADDRINUSE') {
    console.error('[PROCESS] Port already in use, exiting...');
    process.exit(1);
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[PROCESS] SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('[PROCESS] SIGINT received, shutting down gracefully...');
  process.exit(0);
});

init().catch(error => {
  console.error('[INIT] Unhandled error during initialization:', error);
  process.exit(1);
});
