# DigiBo Core API - Setup Guide

This guide will help you get started with the DigiBo Core API in different environments.

## Table of Contents

1. [Local Development with Mock Data](#1-local-development-with-mock-data)
2. [Local Development with Oracle DB](#2-local-development-with-oracle-db)
3. [Test Environment Setup](#3-test-environment-setup)
4. [Production Environment Setup](#4-production-environment-setup)

---

## 1. Local Development with Mock Data

Best for: Quick development without database setup

### Steps:

```bash
# 1. Install dependencies
npm install

# 2. Run in mock mode
npm run dev:mock
```

The API will start on `http://localhost:3000` with mock data.

### What happens:
- `MOCK_ENABLED=true` is set
- No database connection is attempted
- Mock services return predefined data from `src/services/mocks/mockData.js`
- All API endpoints work with sample data

### Test the API:

```bash
# Test FFO endpoint
curl http://localhost:3000/api/ffo/documents/getList

# Test with POST
curl -X POST http://localhost:3000/api/ffo/documents/getList \
  -H "Content-Type: application/json" \
  -d '{"classId": 1, "user": "NEW"}'
```

---

## 2. Local Development with Oracle DB

Best for: Testing with a real database locally

### Option A: Using Docker Compose (Recommended)

```bash
# 1. Start both API and Oracle database
npm run docker:db

# The API will be available at http://localhost:3000
# Oracle will be available at localhost:1521

# 2. Stop everything
npm run docker:db:down
```

### Option B: Using External Oracle DB

```bash
# 1. Install dependencies
npm install

# 2. Create .env file
cp .env.local-db .env

# 3. Update .env with your database credentials
# Edit the file and set:
#   DB_USER=your_username
#   DB_PASSWORD=your_password
#   DB_CONNECTION_STRING=your_host:1521/YOUR_SERVICE

# 4. Run the API
npm run dev:local-db
```

### Load Oracle Packages:

If using a fresh Oracle database, you need to load the PL/SQL packages:

```bash
# Connect to your Oracle database
sqlplus your_user/your_password@localhost:1521/XEPDB1

# Run the installation script
@oracle/ib_install.sql
```

---

## 3. Test Environment Setup

For connecting to a Test Oracle database:

```bash
# 1. Create environment file
cp .env.test .env

# 2. Edit .env and update credentials
# Replace placeholders with actual test database credentials:
#   DB_USER=test_user
#   DB_PASSWORD=test_password
#   DB_CONNECTION_STRING=test-db-host:1521/TESTDB

# 3. Ensure MOCK_ENABLED is false
# The .env.test template already has this set

# 4. Run the application
npm start
```

---

## 4. Production Environment Setup

For connecting to a Production Oracle database:

### Using Environment Variables (Docker/Cloud)

Set these environment variables in your deployment platform:

```bash
NODE_ENV=production
PORT=3000
MOCK_ENABLED=false
DB_USER=prod_user
DB_PASSWORD=prod_password
DB_CONNECTION_STRING=prod-db-host:1521/PRODDB
```

### Using .env File

```bash
# 1. Create production environment file
cp .env.prod .env

# 2. Edit .env and update with production credentials
# IMPORTANT: Keep credentials secure!

# 3. Run the application
npm start
```

### Production Deployment with Docker

```bash
# 1. Build the Docker image
docker build -t digibo-core-api:latest .

# 2. Run the container with environment variables
docker run -d \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e MOCK_ENABLED=false \
  -e DB_USER=prod_user \
  -e DB_PASSWORD=prod_password \
  -e DB_CONNECTION_STRING=prod-host:1521/PRODDB \
  --name digibo-api \
  digibo-core-api:latest
```

---

## Environment Variables Reference

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `NODE_ENV` | Environment name | No | `development` |
| `PORT` | Server port | No | `3000` |
| `MOCK_ENABLED` | Enable mock mode | No | `false` |
| `DB_USER` | Oracle username | Yes (if not mock) | - |
| `DB_PASSWORD` | Oracle password | Yes (if not mock) | - |
| `DB_CONNECTION_STRING` | Oracle connection string | Yes (if not mock) | - |

---

## Troubleshooting

### "Pool not found" error
- Make sure `MOCK_ENABLED=false` when connecting to a database
- Verify database credentials are correct
- Check that the database is accessible from your network

### Port 3000 already in use
```bash
# Change the PORT in your .env file
PORT=3001
```

### Docker container won't start
```bash
# Check logs
docker logs digibo-api-mock  # or digibo-api-db

# Clean up and rebuild
docker-compose down -v
docker-compose build --no-cache
```

### Mock data not returning
- Verify `MOCK_ENABLED=true` in your .env
- Check console logs for "[MOCK MODE]" messages
- Ensure you restarted the server after changing .env

---

## Quick Reference Commands

### Development
```bash
npm run dev:mock        # Local dev with mocks
npm run dev:local-db    # Local dev with DB
npm run dev             # Start with current .env
```

### Docker
```bash
npm run docker:mock          # API only (mock mode)
npm run docker:db            # API + Oracle
npm run docker:oracle        # Oracle only
npm run docker:mock:down     # Stop mock
npm run docker:db:down       # Stop db
npm run docker:oracle:down   # Stop oracle
```

### Testing Endpoints
```bash
# Health check
curl http://localhost:3000/

# FFO Documents
curl http://localhost:3000/api/ffo/documents/all

# Payment Documents
curl http://localhost:3000/api/payments/documents/getList
```

---

## Next Steps

1. Review the API endpoints in the main README.md
2. Explore mock data in `src/services/mocks/mockData.js`
3. Add your own mock data for testing
4. Review the Oracle packages in `oracle/` directory
5. Connect to your Test/Prod databases as needed

For more information, see the main [README.md](README.md).