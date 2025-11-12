# DigiBo Core API - Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       DigiBo UI (Frontend)                   │
│            https://preview--digi-backstage-haven...          │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ HTTP/REST API
                             │
┌────────────────────────────▼────────────────────────────────┐
│                   DigiBo Core API (Backend)                  │
│                     Express.js on Node.js                    │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                    Route Layer                         │ │
│  │  /api/ffo/*  |  /api/payments/*  |  /bodi/*  |  ...   │ │
│  └─────────────────────┬──────────────────────────────────┘ │
│                        │                                     │
│  ┌─────────────────────▼──────────────────────────────────┐ │
│  │              ServiceFactory (Mode Switch)              │ │
│  │         MOCK_ENABLED ? MockService : RealService       │ │
│  └──────────────┬─────────────────────────┬───────────────┘ │
│                 │                         │                  │
│    ┌────────────▼──────────┐  ┌──────────▼──────────────┐  │
│    │    Mock Services      │  │    Real Services        │  │
│    │  - MockFFOService     │  │  - FFOService          │  │
│    │  - MockPaymentService │  │  - PaymentService      │  │
│    │                       │  │  - BaseService         │  │
│    │  Returns:             │  │                        │  │
│    │  - Static mock data   │  │  Connects to:         │  │
│    │  - No DB connection   │  │  - Oracle DB via pool │  │
│    └───────────────────────┘  └──────────┬──────────────┘  │
│                                           │                  │
└───────────────────────────────────────────┼──────────────────┘
                                            │
                         ┌──────────────────▼─────────────────┐
                         │      Oracle Database              │
                         │                                    │
                         │  ┌──────────────────────────────┐ │
                         │  │     PL/SQL Packages          │ │
                         │  │  - BO_FFO                    │ │
                         │  │  - BO_PAYMENT                │ │
                         │  │  - BO_CUSTOMER               │ │
                         │  │  - BO_DOCUMENTS              │ │
                         │  │  - ... many more             │ │
                         │  └──────────────────────────────┘ │
                         │                                    │
                         │  ┌──────────────────────────────┐ │
                         │  │     Database Tables          │ │
                         │  │  - Documents                 │ │
                         │  │  - Customers                 │ │
                         │  │  - Payments                  │ │
                         │  │  - ...                       │ │
                         │  └──────────────────────────────┘ │
                         └────────────────────────────────────┘
```

## Deployment Modes

### Mode 1: Local Development (Mock)
```
┌────────────────┐
│  Developer     │
│  Workstation   │
│                │
│  ┌──────────┐  │
│  │   API    │  │  MOCK_ENABLED=true
│  │  (Node)  │  │  No Database
│  └──────────┘  │
└────────────────┘
```

### Mode 2: Local Development (Docker Mock)
```
┌─────────────────────────┐
│   Docker Container      │
│  ┌──────────────────┐   │
│  │   API (Node)     │   │  MOCK_ENABLED=true
│  │   Port: 3000     │   │  No Database
│  └──────────────────┘   │
└─────────────────────────┘
        │
        │ Port mapping
        │
┌───────▼─────────┐
│  localhost:3000 │
└─────────────────┘
```

### Mode 3: Local Development with Local Oracle
```
┌────────────────────────────────────────┐
│         Docker Compose Network         │
│                                        │
│  ┌──────────────┐  ┌───────────────┐  │
│  │  API         │  │   Oracle XE   │  │
│  │  (Node)      │──│   Database    │  │
│  │  Port: 3000  │  │   Port: 1521  │  │
│  └──────────────┘  └───────────────┘  │
└─────────┬──────────────────────────────┘
          │
          │ Port mapping
          │
┌─────────▼──────────┐
│  localhost:3000    │
└────────────────────┘
```

### Mode 4: Test/Production Environment
```
┌────────────────────┐         ┌──────────────────┐
│   API Server       │         │  Oracle Database │
│   (Node.js)        │────────▶│   (Remote)       │
│                    │  JDBC   │                  │
│   - Docker/K8s     │         │   - Test DB      │
│   - Cloud VM       │         │   - Prod DB      │
└────────────────────┘         └──────────────────┘
```

## Data Flow

### Mock Mode (MOCK_ENABLED=true)
```
Request → Route → ServiceFactory → MockService → mockData.js → Response
```

### Database Mode (MOCK_ENABLED=false)
```
Request → Route → ServiceFactory → RealService → BaseService →
Oracle Connection Pool → PL/SQL Procedure → Database Tables → Response
```

## Service Layer Architecture

### BaseService (Abstract)
```javascript
class BaseService {
    executeProcedure(name, binds)  // Execute PL/SQL procedure
    executeQuery(sql, binds)       // Execute SQL query
}
```

### Real Services (Extend BaseService)
```javascript
FFOService extends BaseService
  - getDocumentsList(classId, status)
  - getAllDocuments()

PaymentService extends BaseService
  - getDocumentsList(classId, user)
```

### Mock Services (Extend MockBaseService)
```javascript
MockFFOService extends MockBaseService
  - getDocumentsList(classId, status)  // Returns mockFFODocuments
  - getAllDocuments()                   // Returns mockFFODocuments

MockPaymentService extends MockBaseService
  - getDocumentsList(classId, user)    // Returns mockPaymentDocuments
```

## Database Connection Pooling

```
┌─────────────────────────────────────────┐
│         Oracle Connection Pool          │
│                                         │
│  ┌──────┐  ┌──────┐  ┌──────┐         │
│  │ Conn │  │ Conn │  │ Conn │         │
│  │  1   │  │  2   │  │  3   │         │
│  └──────┘  └──────┘  └──────┘         │
│                                         │
│  Pool Configuration:                   │
│  - Min: 3 connections                  │
│  - Max: 5 connections                  │
│  - Increment: 1                        │
└─────────────────────────────────────────┘
        │         │         │
        │         │         │
        ▼         ▼         ▼
┌─────────────────────────────────┐
│      Oracle Database            │
└─────────────────────────────────┘
```

## Environment Configuration Strategy

```
.env files hierarchy:

.env.example     ← Template with all options
    │
    ├─ .env.mock         ← Local dev (no DB)
    │
    ├─ .env.local-db     ← Local dev (Docker Oracle)
    │
    ├─ .env.test         ← Test environment
    │
    └─ .env.prod         ← Production environment
```

## Technology Stack

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js 4.x
- **Database Driver**: node-oracledb 6.8.0
- **Environment**: dotenv
- **CORS**: cors
- **Dev Tools**: nodemon

### Database
- **Database**: Oracle Database (XE/Enterprise)
- **Language**: PL/SQL
- **Connection**: Oracle Instant Client

### DevOps
- **Containerization**: Docker
- **Orchestration**: Docker Compose
- **Profiles**: mock, db, oracle-local

## API Endpoints Structure

```
/
├── /                          # Health check
│
├── /api/ffo/                  # Foreign Exchange Orders
│   ├── GET  /documents/getList
│   ├── POST /documents/getList
│   └── GET  /documents/all
│
├── /api/payments/             # Payments
│   ├── GET  /documents/getList
│   ├── POST /documents/getList
│   └── GET  /documents/getDraftCount
│
├── /bodi/                     # BODI operations
│   └── ... (TBD)
│
└── /api/app/                  # Application routes
    └── ... (TBD)
```

## Security Considerations

1. **Environment Variables**: Sensitive data in .env files (not committed to git)
2. **CORS**: Configured origins in src/index.js
3. **Connection Pooling**: Limited pool size to prevent connection exhaustion
4. **Error Handling**: Errors logged but not exposed to client
5. **Input Validation**: Should be added for production use

## Scalability Considerations

1. **Horizontal Scaling**: Multiple API instances can share Oracle connection pool
2. **Load Balancing**: API is stateless, ready for load balancing
3. **Connection Pooling**: Efficient database connection reuse
4. **Mock Mode**: Development doesn't require database resources

## Future Enhancements

- [ ] Add input validation middleware
- [ ] Implement authentication/authorization
- [ ] Add request logging (Morgan/Winston)
- [ ] Add health check endpoints
- [ ] Add metrics/monitoring (Prometheus)
- [ ] Add rate limiting
- [ ] Add API documentation (Swagger/OpenAPI)
- [ ] Add unit tests
- [ ] Add integration tests
- [ ] Add CI/CD pipeline