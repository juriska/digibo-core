const express = require('express');
const cors = require('cors');
const { createPool } = require('./config/database');
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

const port = process.env.PORT || 3000;
const mockEnabled = process.env.MOCK_ENABLED === 'true';

// Import routes
const ffoRoutes = require('./routes/ffo.routes');
const paymentRoutes = require('./routes/payments.routes');
const bodiRoutes = require('./routes/bodi.routes');
const appRoutes = require('./routes/app.routes');

async function init() {
  try {
    if (!mockEnabled) {
      console.log('Initializing database connection...');
      //await createPool();
      console.log('Database connection initialized successfully');
    }

    // Register routes
    app.use('/api/ffo', ffoRoutes);
    app.use('/api/payments', paymentRoutes);
    app.use('/bodi', bodiRoutes);
    app.use('/api/app', appRoutes);

    app.get('/', (req, res) => {
      res.send('✅ API Gateway is up and running');
    });

    app.listen(port, () => {
      console.log(`API Gateway listening on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to initialize application:', error);
    process.exit(1);
  }
}

init().catch(error => {
  console.error('Unhandled error during initialization:', error);
  process.exit(1);
});
