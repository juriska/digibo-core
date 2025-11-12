const oracledb = require('oracledb');
require('dotenv').config();

const mockEnabled = process.env.MOCK_ENABLED === 'true';

if (!mockEnabled) {
    // Configure Oracle date handling only when not in mock mode
    oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
    oracledb.autoCommit = true;
    oracledb.fetchAsString = [oracledb.CLOB];
    oracledb.fetchAsBuffer = [oracledb.BLOB];
    oracledb.fetchInfo = {
        DATE: { type: oracledb.STRING }
    };
}

let pool;

const createPool = async () => {
    if (mockEnabled) {
        console.log('[MOCK MODE] Database connection pool skipped - using mock data');
        return null;
    }

    try {
        if (pool) {
            console.log('Pool already exists, reusing...');
            return pool;
        }

        // Debug environment variables
        console.log('🔍 [DEBUG] Environment variables:');
        console.log('DB_USER:', process.env.DB_USER);
        console.log('DB_PASSWORD:', process.env.DB_PASSWORD ? '***HIDDEN***' : 'UNDEFINED');
        console.log('DB_CONNECTION_STRING:', process.env.DB_CONNECTION_STRING);


        console.log('Creating Oracle connection pool...');
        pool = await oracledb.createPool({
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            connectString: process.env.DB_CONNECTION_STRING,
            poolMin: 3,
            poolMax: 5,
            poolIncrement: 1
        });

        console.log('Oracle connection pool created successfully');
        return pool;
    } catch (err) {
        console.error('Error creating Oracle pool:', err);
        throw err;
    }
};


const getConnection = async () => {
    if (mockEnabled) {
        console.log('[MOCK MODE] Skipping database connection - using mock data');
        return null;
    }

    try {
        if (!pool) {
            console.log('Pool not found, creating new pool...');
            await createPool();
        }

        console.log('Getting connection from pool...');
        return await pool.getConnection();
    } catch (err) {
        console.error('Error getting connection:', err);
        throw err;
    }
};


const initializeDatabase = async () => {
    if (mockEnabled) {
        console.log('[MOCK MODE] Database initialization skipped - using mock data');
        return;
    }

    try {
        await createPool();
        console.log('Database connection initialized successfully');
    } catch (err) {
        console.error('Failed to initialize database:', err);
        process.exit(1);
    }
};


module.exports = {
  createPool,
  getConnection,
  initializeDatabase
};