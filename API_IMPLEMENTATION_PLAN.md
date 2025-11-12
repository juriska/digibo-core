# DigiBo Core API - Complete Implementation Plan

## Executive Summary

This document outlines the plan to implement REST API endpoints for all Oracle PL/SQL packages in the DigiBo Core system.

**Current Status:**
- ✅ 2 packages partially implemented (FFO, Payment)
- ⏳ 10+ packages to be implemented
- ⏳ 100+ procedures/functions to expose as REST endpoints

## Oracle Package Inventory

### 1. BO_FFO (Foreign Exchange Orders) - **PARTIALLY IMPLEMENTED**
**Priority: HIGH** | **Package Methods: 6**

| Method | Type | Current API Status | Endpoint Needed |
|--------|------|-------------------|-----------------|
| `find()` | function | ❌ Missing | `POST /api/ffo/search` |
| `find_my()` | function | ❌ Missing | `GET /api/ffo/my` |
| `ffo()` | procedure | ✅ Partial (getDocumentsList) | `GET /api/ffo/:id` |
| `get_categories()` | function | ❌ Missing | `GET /api/ffo/categories` |
| `categorize()` | function | ❌ Missing | `POST /api/ffo/:id/categorize` |
| `set_processing()` | function | ❌ Missing | `POST /api/ffo/:id/set-processing` |

### 2. BO_PAYMENT (Payments) - **PARTIALLY IMPLEMENTED**
**Priority: HIGH** | **Package Methods: 3+**

| Method | Type | Current API Status | Endpoint Needed |
|--------|------|-------------------|-----------------|
| `find()` | function | ✅ Partial | `POST /api/payments/search` |
| `payment()` | procedure | ✅ Partial | `GET /api/payments/:id` |
| Other payment methods | - | ❌ Missing | TBD after full package analysis |

### 3. BO_CUSTOMER (Customer Management) - **NOT IMPLEMENTED**
**Priority: HIGH** | **Package Methods: 21**

| Method | Type | Endpoint Needed | Description |
|--------|------|-----------------|-------------|
| `customer_exists()` | function | `GET /api/customers/:id/exists` | Check if customer exists |
| `load_user_channels()` | function | `GET /api/customers/:id/channels` | Get user communication channels |
| `load_user()` | procedure | `GET /api/customers/users/:id` | Load user details |
| `load_user_old()` | procedure | `GET /api/customers/users/:id/old` | Load old user format |
| `load_user_info()` | function | `GET /api/customers/users/:id/info` | Get user information |
| `load_user_history()` | function | `GET /api/customers/users/:id/history` | Get user history |
| `load_customer_tree()` | function | `GET /api/customers/:id/tree` | Get customer hierarchy |
| `load_licenses()` | function | `GET /api/customers/:id/licenses` | Get customer licenses |
| `check_license()` | function | `GET /api/customers/licenses/:id/check` | Validate license |
| `check_login()` | function | `POST /api/customers/check-login` | Validate login credentials |
| `check_pswd_num()` | function | `POST /api/customers/check-password-num` | Check password number |
| `check_sign_level()` | function | `POST /api/customers/check-sign-level` | Verify signature level |
| ... (+ 9 more methods) | - | Various | See full package spec |

### 4. BO_DOCUMENTS (Document Management) - **NOT IMPLEMENTED**
**Priority: HIGH** | **Package Methods: 14**

| Method | Type | Endpoint Needed | Description |
|--------|------|-----------------|-------------|
| `history()` | function | `GET /api/documents/:id/history` | Get document history |
| `messageHistory()` | function | `GET /api/documents/:id/messages` | Get message history |
| `set_lock()` | function | `POST /api/documents/:id/lock` | Lock document for editing |
| `set_manual_status()` | procedure | `POST /api/documents/:id/status` | Set document status |
| `set_manual_status_1()` | procedure | `POST /api/documents/:id/status-v2` | Set status with ref |
| `signOwner()` | procedure | `GET /api/documents/sign-owner` | Get signature owner info |
| `get_addr()` | function | `GET /api/documents/:id/addresses` | Get document addresses |
| `get_extensions()` | function | `GET /api/documents/:id/extensions` | Get document extensions |
| `get_remote_officers()` | procedure | `GET /api/documents/remote-officers` | Get remote officers |
| `get_remote_officer()` | function | `GET /api/documents/remote-officer/:id` | Get specific officer |
| `get_ib_signatures()` | function | `GET /api/documents/:id/signatures` | Get IB signatures |
| `set_ManualProcessing()` | function | `POST /api/documents/:id/manual-processing` | Enable manual processing |
| `getChangeOfficerId()` | function | `GET /api/documents/:id/change-officer` | Get change officer |
| `get_by_id()` | function | `GET /api/documents/:id` | Get document by ID |

### 5. BO_AUDITLOG (Audit Logging) - **NOT IMPLEMENTED**
**Priority: MEDIUM** | **Package Methods: 3**

| Method | Type | Endpoint Needed | Description |
|--------|------|-----------------|-------------|
| `find()` | function | `POST /api/audit/search` | Search audit logs |
| `findSession()` | function | `GET /api/audit/session/:id` | Get session audit logs |
| `get_tree()` | function | `GET /api/audit/tree` | Get audit tree structure |

### 6. BO_HELPDESK (Help Desk) - **NOT IMPLEMENTED**
**Priority: MEDIUM** | **Package Methods: 5+**

| Method | Type | Endpoint Needed | Description |
|--------|------|-----------------|-------------|
| `find_user_channel()` | function | `POST /api/helpdesk/find-user-channel` | Find user channel info |
| `load_log()` | function | `GET /api/helpdesk/log` | Load help desk logs |
| `set_password()` | function | `POST /api/helpdesk/set-password` | Reset user password |
| `load_user_channel()` | function | `GET /api/helpdesk/user-channel/:id` | Load user channel details |
| `load_auth_info()` | procedure | `GET /api/helpdesk/auth-info/:id` | Load authentication info |

### 7. BO_SMSAGREEMENT (SMS Agreement) - **NOT IMPLEMENTED**
**Priority: MEDIUM** | **Package Methods: 8+**

| Method | Type | Endpoint Needed | Description |
|--------|------|-----------------|-------------|
| `get_operators()` | function | `GET /api/sms/operators` | Get SMS operators |
| `get_accounts()` | function | `GET /api/sms/accounts` | Get customer accounts |
| `get_logins()` | function | `GET /api/sms/logins` | Get login information |
| `load_rights_1()` | function | `GET /api/sms/rights/level-1` | Load level 1 rights |
| `load_rights_2()` | function | `GET /api/sms/rights/level-2` | Load level 2 rights |
| `load_card_rights()` | function | `GET /api/sms/rights/cards` | Load card rights |
| `load_channel()` | procedure | `GET /api/sms/channel/:id` | Load SMS channel |
| ... | - | Various | Additional methods |

### 8. Additional Packages (From SQL Files)

**Medium Priority Packages:**
- `bo_common` - Common utilities
- `bo_findcustomers` - Customer search
- `bo_gerdep` - Deposit operations
- `bo_requestToPay` - Request to pay

**Lower Priority Packages:**
- `bo_accadmin` - Account administration
- `bo_broker` - Broker operations
- `bo_cards` - Card operations
- `bo_insurance` - Insurance
- `bo_lease_applications` - Lease applications
- `bo_margin` - Margin trading
- `bo_rates` - Exchange rates
- ... and 30+ more

## Implementation Strategy

### Phase 1: Core Functionality (Weeks 1-2)
**Goal: Complete high-priority packages**

1. **Complete BO_FFO Package**
   - Implement all 6 methods
   - Create comprehensive mock data
   - Add validation and error handling

2. **Complete BO_PAYMENT Package**
   - Implement remaining methods
   - Enhanced mock data with various payment types
   - Add input validation

3. **Implement BO_DOCUMENTS Package**
   - Critical for document workflow
   - 14 methods to implement
   - Mock document lifecycle data

4. **Implement BO_CUSTOMER Package**
   - Essential for user management
   - 21 methods to implement
   - Comprehensive customer mock data

### Phase 2: Supporting Services (Weeks 3-4)
**Goal: Implement supporting packages**

1. **BO_AUDITLOG** - Audit trail functionality
2. **BO_HELPDESK** - Support operations
3. **BO_SMSAGREEMENT** - SMS services
4. **bo_findcustomers** - Search functionality
5. **bo_common** - Shared utilities

### Phase 3: Business Operations (Weeks 5-6)
**Goal: Implement business-specific packages**

1. **bo_gerdep** - Deposit operations
2. **bo_requestToPay** - Payment requests
3. **bo_cards** - Card management
4. **bo_rates** - Exchange rates
5. **bo_insurance** - Insurance products

### Phase 4: Extended Services (Weeks 7-8)
**Goal: Complete remaining packages**

1. Implement remaining SQL-based packages
2. Add advanced features
3. Performance optimization
4. Complete test coverage

## Technical Implementation Approach

### 1. Service Layer Architecture

```javascript
// For each Oracle package, create:
src/services/
├── FFOService.js           // Real service
├── PaymentService.js       // Real service
├── CustomerService.js      // NEW
├── DocumentsService.js     // NEW
├── AuditLogService.js      // NEW
├── HelpDeskService.js      // NEW
├── SMSAgreementService.js  // NEW
└── mocks/
    ├── MockFFOService.js
    ├── MockPaymentService.js
    ├── MockCustomerService.js      // NEW
    ├── MockDocumentsService.js     // NEW
    ├── MockAuditLogService.js      // NEW
    ├── MockHelpDeskService.js      // NEW
    ├── MockSMSAgreementService.js  // NEW
    └── mockData.js         // Expand with more data
```

### 2. Route Structure

```
src/routes/
├── ffo.routes.js         // Exists - Expand
├── payments.routes.js    // Exists - Expand
├── customers.routes.js   // NEW
├── documents.routes.js   // NEW
├── audit.routes.js       // NEW
├── helpdesk.routes.js    // NEW
├── sms.routes.js         // NEW
└── common.routes.js      // NEW
```

### 3. API Endpoint Naming Convention

**Pattern:** `/<domain>/<resource>/<action>`

**Examples:**
```
GET    /api/ffo/documents/all
POST   /api/ffo/search
GET    /api/ffo/:id
POST   /api/ffo/:id/categorize
GET    /api/ffo/categories

GET    /api/customers/:id
GET    /api/customers/:id/channels
POST   /api/customers/search
GET    /api/customers/:id/licenses

GET    /api/documents/:id
GET    /api/documents/:id/history
POST   /api/documents/:id/lock
POST   /api/documents/:id/status

POST   /api/audit/search
GET    /api/audit/session/:id
GET    /api/audit/tree
```

### 4. Parameter Binding Strategy

**Oracle Procedure:**
```sql
function find(
    custId in varchar2,
    custName in varchar2,
    statuses in varchar2
) return cursor_t;
```

**REST API:**
```javascript
POST /api/customers/search
Body: {
  "custId": "12345",
  "custName": "John Doe",
  "statuses": "ACTIVE,PENDING"
}
```

**Service Implementation:**
```javascript
async searchCustomers(custId, custName, statuses) {
    const binds = {
        P_CUST_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: custId },
        P_CUST_NAME: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: custName },
        P_STATUSES: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: statuses },
        P_CURSOR: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
    };
    return await this.executeProcedure('find', binds);
}
```

### 5. Mock Data Strategy

Create realistic mock data for each domain:

```javascript
// mockData.js
module.exports = {
    // FFO
    mockFFODocuments: [...],
    mockFFOCategories: [...],

    // Payments
    mockPaymentDocuments: [...],
    mockPaymentTemplates: [...],

    // Customers
    mockCustomers: [...],
    mockCustomerChannels: [...],
    mockCustomerLicenses: [...],

    // Documents
    mockDocuments: [...],
    mockDocumentHistory: [...],
    mockDocumentSignatures: [...],

    // Audit
    mockAuditLogs: [...],
    mockAuditEvents: [...],

    // etc...
};
```

### 6. Error Handling Pattern

```javascript
router.post('/customers/search', async (req, res) => {
    try {
        const { custId, custName, statuses } = req.body;

        // Validation
        if (!custId && !custName) {
            return res.status(400).json({
                error: 'At least one search parameter required'
            });
        }

        const result = await customerService.search(custId, custName, statuses);
        res.json(result);
    } catch (err) {
        console.error('Error in customer search:', err);
        res.status(500).json({
            error: 'Internal server error',
            message: process.env.NODE_ENV === 'development' ? err.message : undefined
        });
    }
});
```

## Implementation Checklist

### Per Package Implementation

- [ ] Analyze package specification (`.pks` file)
- [ ] Document all functions/procedures with parameters
- [ ] Create Service class extending BaseService
- [ ] Create Mock Service class extending MockBaseService
- [ ] Add service to ServiceFactory
- [ ] Create route file with all endpoints
- [ ] Create comprehensive mock data
- [ ] Add input validation
- [ ] Add error handling
- [ ] Test all endpoints in mock mode
- [ ] Test all endpoints with real DB
- [ ] Document API endpoints
- [ ] Add to Postman/OpenAPI spec

### Overall Project Tasks

- [ ] Update ServiceFactory with all new services
- [ ] Register all routes in `src/index.js`
- [ ] Create comprehensive mock data file
- [ ] Add request validation middleware
- [ ] Add authentication middleware (if needed)
- [ ] Create API documentation (Swagger/OpenAPI)
- [ ] Create Postman collection
- [ ] Add integration tests
- [ ] Performance testing
- [ ] Security review

## Estimated Effort

| Phase | Packages | Endpoints | Effort (Days) | Team Size |
|-------|----------|-----------|---------------|-----------|
| Phase 1 | 4 | ~50 | 10 days | 2 developers |
| Phase 2 | 5 | ~30 | 8 days | 2 developers |
| Phase 3 | 5 | ~25 | 6 days | 2 developers |
| Phase 4 | 10+ | ~40 | 10 days | 2 developers |
| **Total** | **24+** | **~145** | **34 days** | **2 developers** |

## Next Steps

1. **Immediate Actions:**
   - Review and approve this plan
   - Prioritize package implementation order based on business needs
   - Assign developers to Phase 1 packages

2. **Week 1 Goals:**
   - Complete BO_FFO package (all 6 methods)
   - Complete BO_PAYMENT package
   - Begin BO_DOCUMENTS package

3. **Success Metrics:**
   - All high-priority packages completed by end of Week 2
   - 100% mock mode coverage for local development
   - All endpoints tested with real database
   - API documentation completed

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Complex PL/SQL procedures | High | Analyze package body, consult with Oracle DBA |
| Missing Oracle DB access | High | Comprehensive mock mode allows parallel development |
| Parameter mapping issues | Medium | Document all parameter types, create mapping guide |
| Performance issues | Medium | Connection pooling, optimize queries, add caching |
| Breaking changes | Low | Version API endpoints (/api/v1/, /api/v2/) |

## Appendix A: Full Package List

1. ✅ BO_FFO.pks (Partial)
2. ✅ BO_PAYMENT.pks (Partial)
3. ❌ BO_CUSTOMER.pks
4. ❌ BO_DOCUMENTS.pks
5. ❌ BO_AUDITLOG.pks
6. ❌ BO_HELPDESK.pks
7. ❌ BO_SMSAGREEMENT.pks
8. ❌ DIGI_FAX_DIGIFAXREPL.pks
9. ❌ bo_findcustomers.pks
10. ❌ bo_gerdep.pks
11. ❌ bo_requestToPay.pks
12. ❌ bo_common.sql
13. ❌ bo_cards.sql
14. ❌ bo_rates.sql
15. ❌ ... (+30 more SQL packages)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-11
**Author:** DigiBo Development Team