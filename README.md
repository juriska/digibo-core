# DigiBo Core API

Node.js Express API Gateway for DigiBo application that provides REST endpoints to interact with Oracle PL/SQL procedures. Supports both mock mode for local development and real Oracle database connections for Test/Production environments.

## Features

- Express.js REST API
- Oracle Database connectivity via PL/SQL stored procedures
- Mock mode for local development without database
- Docker containerization support
- Connection pooling for efficient database access
- Environment-based configuration

## Architecture

```
src/
├── config/          # Database configuration
├── routes/          # Express route handlers
├── services/        # Business logic layer
│   └── mocks/      # Mock services for local dev
└── index.js        # Application entry point

oracle/             # Oracle PL/SQL packages and scripts
```

## Prerequisites

- Node.js 18+
- Docker & Docker Compose (optional, for containerized deployment)
- Oracle Database (for Test/Prod environments)

## Quick Start

### Option 1: Local Development with Mock Data (No Database Required)

```bash
# Install dependencies
npm install

# Run with mock data
npm run dev:mock
```

### Option 2: Local Development with Local Oracle DB (Docker)

```bash
# Start local Oracle XE container
npm run docker:oracle

# Run API with local DB connection
npm run dev:local-db
```

### Option 3: Docker Compose - Mock Mode

```bash
# Run API in mock mode via Docker
npm run docker:mock

# Stop
npm run docker:mock:down
```

### Option 4: Docker Compose - Database Mode

```bash
# Run API + Oracle DB via Docker
npm run docker:db

# Stop
npm run docker:db:down
```

## Environment Configuration

The project supports multiple environment configurations through `.env` files:

- `.env.mock` - Local development with mock data (no database)
- `.env.local-db` - Local development with Docker Oracle XE
- `.env.test` - Test environment configuration
- `.env.prod` - Production environment configuration
- `.env.example` - Template with all available options

### Key Environment Variables

```bash
# Server
PORT=3000
NODE_ENV=development

# Mock Mode Toggle
MOCK_ENABLED=true  # true = mock data, false = real database

# Oracle Database (required when MOCK_ENABLED=false)
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_CONNECTION_STRING=hostname:1521/SERVICE_NAME
```

## API Endpoints

### FFO (Foreign Exchange Orders)

- `GET /api/ffo/documents/getList` - Get FFO documents (classId=1, status=NEW)
- `POST /api/ffo/documents/getList` - Get FFO documents with custom filters
- `GET /api/ffo/documents/all` - Get all FFO documents

### Payments

- `GET /api/payments/documents/getList` - Get payment documents
- `POST /api/payments/documents/getList` - Get payment documents with filters
- `GET /api/payments/documents/getDraftCount` - Get count of draft payments

### Example Request

```bash
curl -X POST http://localhost:3000/api/ffo/documents/getList \
  -H "Content-Type: application/json" \
  -d '{"classId": 1, "user": "NEW"}'
```

## Development Workflow

### Working with Mock Data

1. Mock data is defined in `src/services/mocks/mockData.js`
2. Mock services implement the same interface as real services
3. No database connection required
4. Instant startup and feedback

```bash
npm run dev:mock
```

### Working with Local Oracle DB

1. Start the local Oracle container
2. Load your PL/SQL packages into the database
3. Connect the API to the local DB

```bash
# Start Oracle XE
npm run docker:oracle

# Wait for Oracle to initialize (first time takes ~2-3 minutes)

# Run API with DB connection
npm run dev:local-db
```

### Connecting to Test/Production Databases

1. Copy the appropriate environment file:
   ```bash
   cp .env.test .env  # or .env.prod
   ```

2. Update database credentials:
   ```bash
   DB_USER=your_user
   DB_PASSWORD=your_password
   DB_CONNECTION_STRING=db-host:1521/SERVICE_NAME
   ```

3. Run the application:
   ```bash
   npm start
   ```

## Docker Compose Profiles

The `docker-compose.yml` uses profiles to run different configurations:

- `mock` - API only, with mock data
- `db` - API + Oracle DB connection
- `oracle-local` - Local Oracle XE database

## Available Scripts

```bash
# Development
npm start              # Start production server
npm run dev            # Start development server with nodemon
npm run dev:mock       # Start with mock data
npm run dev:local-db   # Start with local Oracle DB

# Docker - Mock Mode
npm run docker:mock         # Start API in mock mode
npm run docker:mock:down    # Stop mock mode

# Docker - Database Mode
npm run docker:db           # Start API + Oracle
npm run docker:db:down      # Stop database mode

# Docker - Oracle Only
npm run docker:oracle       # Start Oracle XE container
npm run docker:oracle:down  # Stop and remove Oracle container
```

## Oracle Database Setup

The `oracle/` directory contains PL/SQL packages and setup scripts:

- Package specifications (`.pks` files)
- Package bodies (`.pkb` files)
- Installation and patch scripts

To install packages in your Oracle database, connect with SQL*Plus or SQL Developer and run the appropriate scripts.

## Switching Between Mock and Database Mode

The application automatically switches between mock and real services based on the `MOCK_ENABLED` environment variable:

- `MOCK_ENABLED=true` - Uses mock services, no database connection
- `MOCK_ENABLED=false` - Uses real services, connects to Oracle database

This is handled by the `ServiceFactory` in `src/services/ServiceFactory.js`.

## Troubleshooting

### Port Already in Use

If port 3000 is already in use, change the `PORT` in your `.env` file.

### Oracle Connection Issues

1. Check database credentials in `.env`
2. Verify Oracle database is running and accessible
3. Check connection string format: `hostname:port/service_name`
4. Review logs for detailed error messages

### Docker Issues

```bash
# Clean up all containers and volumes
docker-compose down -v

# Rebuild containers from scratch
docker-compose build --no-cache
```

## License

[Your License Here] 