# DigiBo Core API - Developer Guide

## Quick Start for Adding New Endpoints

This guide shows you how to add new API endpoints for Oracle PL/SQL packages.

## Step-by-Step: Adding a New Package

### Example: Adding BO_CUSTOMER Package

### Step 1: Analyze the Oracle Package

Look at the package specification file:

```bash
cat oracle/BO_CUSTOMER.pks
```

Identify all functions and procedures. Example:
```sql
function customer_exists(pId in varchar2) return number;
function load_user_channels(pId in varchar2) return cursor_t;
procedure load_user(pId in out number, pName out varchar2, ...);
```

### Step 2: Create the Real Service

**File:** `src/services/CustomerService.js`

```javascript
const oracledb = require('oracledb');
const BaseService = require('./BaseService');

class CustomerService extends BaseService {
    constructor() {
        super('BOCustomer');  // Oracle package name
    }

    // Method 1: Simple function returning a value
    async customerExists(customerId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: customerId
            },
            P_RESULT: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            }
        };

        // For functions returning values (not cursors)
        const result = await this.executeQuery(
            `BEGIN :P_RESULT := ${this.packageName}.customer_exists(:P_ID); END;`,
            binds
        );
        return result.outBinds.P_RESULT;
    }

    // Method 2: Function returning cursor (list of data)
    async loadUserChannels(userId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: userId
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('load_user_channels', binds);
    }

    // Method 3: Procedure with multiple OUT parameters
    async loadUser(userId) {
        const binds = {
            P_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_INOUT,
                val: userId
            },
            P_NAME: {
                type: oracledb.STRING,
                dir: oracledb.BIND_OUT
            },
            P_EMAIL: {
                type: oracledb.STRING,
                dir: oracledb.BIND_OUT
            },
            // ... add all OUT parameters
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN ${this.packageName}.load_user(:P_ID, :P_NAME, :P_EMAIL); END;`,
                binds
            );

            return result.outBinds;
        } finally {
            await connection.close();
        }
    }
}

module.exports = CustomerService;
```

### Step 3: Create Mock Service

**File:** `src/services/mocks/MockCustomerService.js`

```javascript
const MockBaseService = require('./MockBaseService');
const { mockCustomers, mockCustomerChannels } = require('./mockData');

class MockCustomerService extends MockBaseService {
    constructor() {
        super('BOCustomer');
    }

    async customerExists(customerId) {
        console.log(`[MOCK] BOCustomer.customer_exists(${customerId})`);

        const exists = mockCustomers.some(c => c.ID === customerId);
        return exists ? 1 : 0;
    }

    async loadUserChannels(userId) {
        console.log(`[MOCK] BOCustomer.load_user_channels(${userId})`);

        return mockCustomerChannels.filter(c => c.USER_ID === userId);
    }

    async loadUser(userId) {
        console.log(`[MOCK] BOCustomer.load_user(${userId})`);

        const customer = mockCustomers.find(c => c.ID === userId);
        if (!customer) {
            throw new Error('Customer not found');
        }

        return {
            P_ID: customer.ID,
            P_NAME: customer.NAME,
            P_EMAIL: customer.EMAIL,
            // ... return all fields
        };
    }
}

module.exports = MockCustomerService;
```

### Step 4: Add Mock Data

**File:** `src/services/mocks/mockData.js`

```javascript
// Add to existing mockData.js file

const mockCustomers = [
    {
        ID: 'C001',
        NAME: 'John Doe',
        EMAIL: 'john.doe@example.com',
        PHONE: '+1234567890',
        STATUS: 'ACTIVE',
        CREATED_DATE: '2024-01-01'
    },
    {
        ID: 'C002',
        NAME: 'Jane Smith',
        EMAIL: 'jane.smith@example.com',
        PHONE: '+0987654321',
        STATUS: 'ACTIVE',
        CREATED_DATE: '2024-01-15'
    }
];

const mockCustomerChannels = [
    {
        ID: 1,
        USER_ID: 'C001',
        CHANNEL: 'WEB',
        STATUS: 'ACTIVE',
        CREATED_DATE: '2024-01-01'
    },
    {
        ID: 2,
        USER_ID: 'C001',
        CHANNEL: 'MOBILE',
        STATUS: 'ACTIVE',
        CREATED_DATE: '2024-01-02'
    }
];

module.exports = {
    // ... existing exports
    mockCustomers,
    mockCustomerChannels
};
```

### Step 5: Update ServiceFactory

**File:** `src/services/ServiceFactory.js`

```javascript
const mockEnabled = process.env.MOCK_ENABLED === 'true';

// Import real services
const FFOService = require('./FFOService');
const PaymentService = require('./PaymentService');
const CustomerService = require('./CustomerService');  // NEW

// Import mock services
const MockFFOService = require('./mocks/MockFFOService');
const MockPaymentService = require('./mocks/MockPaymentService');
const MockCustomerService = require('./mocks/MockCustomerService');  // NEW

module.exports = {
    FFOService: mockEnabled ? MockFFOService : FFOService,
    PaymentService: mockEnabled ? MockPaymentService : PaymentService,
    CustomerService: mockEnabled ? MockCustomerService : CustomerService,  // NEW
};
```

### Step 6: Create Routes

**File:** `src/routes/customers.routes.js`

```javascript
const express = require('express');
const router = express.Router();
const { CustomerService } = require('../services/ServiceFactory');

const customerService = new CustomerService();

// GET /api/customers/:id/exists
router.get('/:id/exists', async (req, res) => {
    try {
        const { id } = req.params;
        const exists = await customerService.customerExists(id);
        res.json({ exists: exists === 1 });
    } catch (err) {
        console.error('Error checking customer existence:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/customers/users/:id/channels
router.get('/users/:id/channels', async (req, res) => {
    try {
        const { id } = req.params;
        const channels = await customerService.loadUserChannels(id);
        res.json(channels);
    } catch (err) {
        console.error('Error loading user channels:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/customers/users/:id
router.get('/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const user = await customerService.loadUser(parseInt(id));
        res.json(user);
    } catch (err) {
        console.error('Error loading user:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
```

### Step 7: Register Routes

**File:** `src/index.js`

```javascript
// Import routes
const ffoRoutes = require('./routes/ffo.routes');
const paymentRoutes = require('./routes/payments.routes');
const bodiRoutes = require('./routes/bodi.routes');
const appRoutes = require('./routes/app.routes');
const customerRoutes = require('./routes/customers.routes');  // NEW

// Register routes
app.use('/api/ffo', ffoRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/bodi', bodiRoutes);
app.use('/api/app', appRoutes);
app.use('/api/customers', customerRoutes);  // NEW
```

### Step 8: Test Your Endpoints

**In Mock Mode:**
```bash
npm run dev:mock

# Test the endpoints
curl http://localhost:3000/api/customers/C001/exists
curl http://localhost:3000/api/customers/users/C001/channels
curl http://localhost:3000/api/customers/users/C001
```

**With Real Database:**
```bash
npm run dev:local-db

# Test with real data
curl http://localhost:3000/api/customers/REAL_ID/exists
```

## Common Patterns

### Pattern 1: Simple Function Returning Value

**Oracle:**
```sql
function get_count(pId in varchar2) return number;
```

**Service:**
```javascript
async getCount(id) {
    const binds = {
        P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: id },
        P_RESULT: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    };
    const result = await this.executeQuery(
        `BEGIN :P_RESULT := ${this.packageName}.get_count(:P_ID); END;`,
        binds
    );
    return result.outBinds.P_RESULT;
}
```

### Pattern 2: Function Returning Cursor

**Oracle:**
```sql
function find(pName in varchar2) return cursor_t;
```

**Service:**
```javascript
async find(name) {
    const binds = {
        P_NAME: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: name },
        P_CURSOR: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
    };
    return await this.executeProcedure('find', binds);
}
```

### Pattern 3: Procedure with OUT Parameters

**Oracle:**
```sql
procedure get_details(
    pId in varchar2,
    pName out varchar2,
    pStatus out number
);
```

**Service:**
```javascript
async getDetails(id) {
    const binds = {
        P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: id },
        P_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
        P_STATUS: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    };
    const connection = await getConnection();
    try {
        const result = await connection.execute(
            `BEGIN ${this.packageName}.get_details(:P_ID, :P_NAME, :P_STATUS); END;`,
            binds
        );
        return result.outBinds;
    } finally {
        await connection.close();
    }
}
```

### Pattern 4: Function with INOUT Parameter

**Oracle:**
```sql
function update_status(pId in out number, pStatus in varchar2) return number;
```

**Service:**
```javascript
async updateStatus(id, status) {
    const binds = {
        P_ID: { type: oracledb.NUMBER, dir: oracledb.BIND_INOUT, val: id },
        P_STATUS: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: status },
        P_RESULT: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    };
    const connection = await getConnection();
    try {
        const result = await connection.execute(
            `BEGIN :P_RESULT := ${this.packageName}.update_status(:P_ID, :P_STATUS); END;`,
            binds
        );
        return {
            result: result.outBinds.P_RESULT,
            newId: result.outBinds.P_ID
        };
    } finally {
        await connection.close();
    }
}
```

## Oracle Data Type Mapping

| Oracle Type | oracledb Type | JavaScript Type |
|-------------|---------------|-----------------|
| VARCHAR2 | `oracledb.STRING` | string |
| NUMBER | `oracledb.NUMBER` | number |
| DATE | `oracledb.DATE` | Date or string |
| CLOB | `oracledb.CLOB` | string (auto-fetched) |
| BLOB | `oracledb.BLOB` | Buffer |
| CURSOR | `oracledb.CURSOR` | ResultSet |

## Parameter Direction Types

- `oracledb.BIND_IN` - Input parameter
- `oracledb.BIND_OUT` - Output parameter
- `oracledb.BIND_INOUT` - Input/Output parameter

## Error Handling Best Practices

```javascript
router.post('/customers/search', async (req, res) => {
    try {
        const { name, status } = req.body;

        // Input validation
        if (!name && !status) {
            return res.status(400).json({
                error: 'Bad Request',
                message: 'At least one search parameter is required'
            });
        }

        // Call service
        const result = await customerService.search(name, status);

        // Return success
        res.json(result);
    } catch (err) {
        console.error('Error in customer search:', err);

        // Don't expose internal errors in production
        const response = {
            error: 'Internal Server Error'
        };

        if (process.env.NODE_ENV === 'development') {
            response.message = err.message;
            response.stack = err.stack;
        }

        res.status(500).json(response);
    }
});
```

## Testing Checklist

For each new endpoint:

- [ ] Test in mock mode with valid data
- [ ] Test in mock mode with invalid data
- [ ] Test in mock mode with edge cases
- [ ] Test with real DB connection
- [ ] Verify error handling
- [ ] Check response format
- [ ] Test parameter validation
- [ ] Document in API docs

## Debugging Tips

### Enable Detailed Logging

```javascript
// In your service method
console.log('[DEBUG] Calling Oracle procedure:', procedureName);
console.log('[DEBUG] Binds:', JSON.stringify(binds, null, 2));
```

### Check Mock Mode

```bash
# Verify mock mode is enabled
curl http://localhost:3000/api/customers/test/exists
# Look for [MOCK MODE] in console logs
```

### Test Oracle Connection

```bash
# Check database connection
npm run dev:local-db

# Look for these messages:
# "Oracle connection pool created successfully"
# "Getting connection from pool..."
```

## Common Issues

### Issue: "ORA-06550: line 1, column 7: PLS-00201: identifier 'PACKAGE.METHOD' must be declared"

**Solution:** Check package name and method name spelling in your service class.

### Issue: "TypeError: Cannot read property 'outBinds' of undefined"

**Solution:** Make sure you're using the correct bind parameter direction (IN/OUT/INOUT).

### Issue: Mock service not being used

**Solution:**
1. Check `MOCK_ENABLED=true` in .env
2. Verify ServiceFactory exports the mock service
3. Restart the server

### Issue: "ORA-01008: not all variables bound"

**Solution:** Ensure all bind parameters match the procedure signature exactly.

## Pro Tips

1. **Start with Mock Service** - Build and test mock service first before connecting to DB
2. **Use Descriptive Names** - Name your methods after the Oracle procedure but in camelCase
3. **Validate Inputs** - Always validate request parameters before calling services
4. **Log Everything** - Add console.log statements for debugging
5. **Copy Existing Code** - Use FFOService and PaymentService as templates
6. **Test Incrementally** - Test each method immediately after implementing it
7. **Document Parameters** - Add JSDoc comments to document parameter types

## Quick Reference

```bash
# Start development with mocks
npm run dev:mock

# Start with local database
npm run dev:local-db

# Run in Docker with mocks
npm run docker:mock

# Run in Docker with database
npm run docker:db

# Test endpoint
curl http://localhost:3000/api/<resource>/<path>
```

## Next Steps

1. Choose a package to implement from `API_IMPLEMENTATION_PLAN.md`
2. Follow this guide step-by-step
3. Test thoroughly in mock mode
4. Test with real database
5. Document your endpoints
6. Move to next package

Happy coding! 🚀