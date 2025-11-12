# BO_DOCUMENTS Package - Complete Implementation Guide

## Overview

The BO_DOCUMENTS package provides **cross-document** utility functions that work with ANY document type (payments, FFO, requests-to-pay, etc.). It handles document lifecycle operations like history, locking, status updates, and metadata retrieval.

**Key Insight:** BO_DOCUMENTS works with the generic `documents` table, while specific document packages (BO_PAYMENT, BO_FFO, etc.) work with the typed structures defined in `bo_types.sql`.

## Oracle Types & Structures

### Core Document Types (from bo_types.sql)

All document operations can work with these types:
- `payment_t` - Regular payments
- `req_to_pay_t` - Request-to-pay documents
- `ffo_t` - Free format orders
- `card_message_t` - Card-related messages
- `broker_t`, `insurance_t`, `margin_t`, etc.

### Document History Type (audit_log_t)

```sql
type audit_log_t as object (
    id number(14),
    session_no number(14),
    time_stamp date,
    machine varchar2(64),
    orig_user varchar2(60),
    orig_officer varchar2(20),
    obj_user varchar2(60),
    obj_officer varchar2(20),
    doc_info varchar2(64),
    details varchar2(2000),
    channel number(2),
    eventName varchar2(211),
    eventGroup varchar2(211),
    uv number(1),
    doc_id number(14),
    class_id number(5),
    ...
);
```

## BO_DOCUMENTS Methods Analysis

### 1. history(pId) - Document Audit History

**Oracle Signature:**
```sql
function history(pId in varchar2) return cursor_t;
```

**Implementation (lines 3-19 in BO_DOCUMENTS.pkb):**
```sql
open rv for select
    al.id,
    al.event_type_id,
    al.event_date timestamp,
    al.cur_pmt_status status,
    o.name officer,
    al.details details
from audit_log al, session_log sl, officers o
where payment_id = pId and cur_pmt_status != RBA_CONST.DRAFT
    and al.session_id = sl.id
    and o.id(+) = sl.user_id;
```

**Expected JSON Structure:**
```json
[
  {
    "id": 123456,
    "event_type_id": 45,
    "timestamp": "2025-11-11T14:30:00Z",
    "status": 3,
    "officer": "John Smith",
    "details": "Document approved by system"
  },
  {
    "id": 123457,
    "event_type_id": 47,
    "timestamp": "2025-11-11T15:15:00Z",
    "status": 5,
    "officer": "Jane Doe",
    "details": "Document processed successfully"
  }
]
```

---

### 2. messageHistory(pId) - Message-Related History

**Oracle Signature:**
```sql
function messageHistory(pId in varchar2) return cursor_t;
```

**Implementation (lines 21-33):**
```sql
open rv for select
    al.id,
    al.event_type_id,
    al.event_date timestamp,
    al.cur_pmt_status status,
    al.details details
from audit_log al
where message_id = pId;
```

**Expected JSON Structure:**
```json
[
  {
    "id": 789012,
    "event_type_id": 120,
    "timestamp": "2025-11-11T10:00:00Z",
    "status": 1,
    "details": "Message received from customer"
  }
]
```

---

### 3. set_lock(pId) - Lock Document for Editing

**Oracle Signature:**
```sql
function set_lock(
    pId in varchar2,
    pStatus out integer,
    pOfficerName out varchar2,
    pOfficerPhone out varchar2
) return integer;
```

**Returns:**
- `0` = Lock acquired successfully
- `1` = Document already locked by another user

**Expected JSON Structure (Success):**
```json
{
  "lockAcquired": true,
  "status": 2,
  "message": "Document locked successfully"
}
```

**Expected JSON Structure (Failure):**
```json
{
  "lockAcquired": false,
  "lockedBy": {
    "name": "Officer Name",
    "phone": "+371 12345678"
  },
  "message": "Document is currently being edited by another user"
}
```

---

### 4. set_manual_status(pId, reason, pNewStatus, pMessageId) - Update Status

**Oracle Signature:**
```sql
procedure set_manual_status(
    pId in varchar2,
    reason in varchar2,
    pNewStatus in integer,
    pMessageId in integer
);
```

**Implementation (lines 109-131):**
- Updates document status
- Records reason in info_to_customer field
- Logs event in audit_log

**Expected JSON Request:**
```json
{
  "documentId": "12345",
  "reason": "Approved after verification",
  "newStatus": 5,
  "messageId": 9876
}
```

**Expected JSON Response:**
```json
{
  "success": true,
  "documentId": "12345",
  "newStatus": 5,
  "previousStatus": 3,
  "message": "Document status updated successfully"
}
```

---

### 5. set_manual_status_1(pId, reason, pNewStatus, pMessageId, pBankReference) - Update Status with Bank Ref

**Oracle Signature:**
```sql
procedure set_manual_status_1(
    pId in varchar2,
    reason in varchar2,
    pNewStatus in integer,
    pMessageId in integer,
    pBankRefference in varchar2
);
```

**Expected JSON Request:**
```json
{
  "documentId": "12345",
  "reason": "Processed in core banking",
  "newStatus": 10,
  "messageId": 9876,
  "bankReference": "GLOBUS/2025/12345"
}
```

---

### 6. signOwner(certId, signDate) - Get Signature Owner Info

**Oracle Signature:**
```sql
procedure signOwner(
    certId in varchar2,
    signDate in date,
    uName out varchar2,
    legalId out varchar2
);
```

**Expected JSON Response:**
```json
{
  "userName": "John Doe",
  "legalId": "123456-12345",
  "certificateId": "CERT_ABC123",
  "signatureDate": "2025-11-11T14:30:00Z"
}
```

---

### 7. get_addr(pId) - Get Document Addresses

**Oracle Signature:**
```sql
function get_addr(pId in varchar2) return cursor_t;
```

**Implementation (lines 157-170):**
```sql
open rv for select
    type_id,
    receiving_type,
    bank_office_name,
    addr_zip || ', ' || addr_country || ', ' ||
    addr_city || ', ' || addr_street || ', ' ||
    addr_house || ', ' || addr_apart addr
from document_addresses
where document_id = pId;
```

**Expected JSON Structure:**
```json
[
  {
    "type_id": 1,
    "receiving_type": "MAIL",
    "bank_office_name": "Main Branch",
    "addr": "LV-1050, LV, Riga, Brivibas street, 123, 45"
  }
]
```

---

### 8. get_extensions(pId) - Get Document Extensions

**Oracle Signature:**
```sql
function get_extensions(pId in varchar2) return cursor_t;
```

**Implementation (lines 172-183):**
```sql
open rv for select
    dictionary_id,
    additional_info,
    block_number
from document_extensions
where document_id = pId
order by dictionary_id;
```

**Expected JSON Structure:**
```json
[
  {
    "dictionary_id": 1001,
    "additional_info": "Extra verification required",
    "block_number": 1
  },
  {
    "dictionary_id": 1002,
    "additional_info": "Compliance check passed",
    "block_number": 2
  }
]
```

---

### 9. get_remote_officers() - Get Remote Officers List

**Oracle Signature:**
```sql
procedure get_remote_officers(dept_id out num_table_type);
```

**Expected JSON Structure:**
```json
{
  "departmentIds": [101, 102, 103, 105, 120]
}
```

---

### 10. get_remote_officer(officer_id) - Get Specific Remote Officer

**Oracle Signature:**
```sql
function get_remote_officer(officer_id in integer) return integer;
```

**Expected JSON Structure:**
```json
{
  "officerId": 12345,
  "isRemote": true,
  "remoteDepartmentId": 101
}
```

---

### 11. get_ib_signatures(pDocId) - Get Internet Banking Signatures

**Oracle Signature:**
```sql
function get_ib_signatures(pDocId in varchar2) return cursor_t;
```

**Expected JSON Structure:**
```json
[
  {
    "name": "John Doe",
    "signature_action": "APPROVE",
    "signature_level": 2,
    "signature_date": "2025-11-11T14:30:00Z",
    "signature_cdevice_type_id": 5,
    "signature_cdevice_serial": "DEVICE_ABC123",
    "document_batch_id": 98765
  }
]
```

---

### 12. set_ManualProcessing(pId) - Enable Manual Processing

**Oracle Signature:**
```sql
function set_ManualProcessing(pId in varchar2) return integer;
```

**Expected JSON Response:**
```json
{
  "success": true,
  "documentId": "12345",
  "manualProcessingEnabled": true
}
```

---

### 13. getChangeOfficerId(pId) - Get Change Officer

**Oracle Signature:**
```sql
function getChangeOfficerId(pId in varchar2) return integer;
```

**Expected JSON Structure:**
```json
{
  "documentId": "12345",
  "changeOfficerId": 7890,
  "changeOfficerName": "Jane Smith"
}
```

---

### 14. get_by_id(pId) - Get Basic Document Info

**Oracle Signature:**
```sql
function get_by_id(
    pId in number,
    pStatus out integer,
    pOfficerID out number,
    pITC out varchar2
) return integer;
```

**Expected JSON Structure:**
```json
{
  "id": 12345,
  "status": 3,
  "officerId": 7890,
  "infoToCustomer": "Your document has been approved",
  "found": true
}
```

---

## Implementation Plan

### Step 1: Create DocumentsService.js

```javascript
const oracledb = require('oracledb');
const BaseService = require('./BaseService');

class DocumentsService extends BaseService {
    constructor() {
        super('BODocuments');
    }

    // 1. Get document history
    async getHistory(documentId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_CURSOR: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        };
        return await this.executeProcedure('history', binds);
    }

    // 2. Get message history
    async getMessageHistory(documentId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_CURSOR: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        };
        return await this.executeProcedure('messageHistory', binds);
    }

    // 3. Lock document
    async setLock(documentId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_STATUS: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_OFFICER_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT, maxSize: 200 },
            P_OFFICER_PHONE: { type: oracledb.STRING, dir: oracledb.BIND_OUT, maxSize: 50 },
            P_RESULT: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_RESULT := ${this.packageName}.set_lock(:P_ID, :P_STATUS, :P_OFFICER_NAME, :P_OFFICER_PHONE); END;`,
                binds
            );

            return {
                lockAcquired: result.outBinds.P_RESULT === 0,
                status: result.outBinds.P_STATUS,
                lockedBy: result.outBinds.P_RESULT === 1 ? {
                    name: result.outBinds.P_OFFICER_NAME,
                    phone: result.outBinds.P_OFFICER_PHONE
                } : null
            };
        } finally {
            await connection.close();
        }
    }

    // 4. Set manual status
    async setManualStatus(documentId, reason, newStatus, messageId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_REASON: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: reason },
            P_NEW_STATUS: { type: oracledb.NUMBER, dir: oracledb.BIND_IN, val: newStatus },
            P_MESSAGE_ID: { type: oracledb.NUMBER, dir: oracledb.BIND_IN, val: messageId }
        };

        const connection = await getConnection();
        try {
            await connection.execute(
                `BEGIN ${this.packageName}.set_manual_status(:P_ID, :P_REASON, :P_NEW_STATUS, :P_MESSAGE_ID); END;`,
                binds
            );
            return { success: true };
        } finally {
            await connection.close();
        }
    }

    // 5. Set manual status with bank reference
    async setManualStatusWithRef(documentId, reason, newStatus, messageId, bankRef) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_REASON: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: reason },
            P_NEW_STATUS: { type: oracledb.NUMBER, dir: oracledb.BIND_IN, val: newStatus },
            P_MESSAGE_ID: { type: oracledb.NUMBER, dir: oracledb.BIND_IN, val: messageId },
            P_BANK_REF: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: bankRef }
        };

        const connection = await getConnection();
        try {
            await connection.execute(
                `BEGIN ${this.packageName}.set_manual_status_1(:P_ID, :P_REASON, :P_NEW_STATUS, :P_MESSAGE_ID, :P_BANK_REF); END;`,
                binds
            );
            return { success: true };
        } finally {
            await connection.close();
        }
    }

    // 6. Get signature owner
    async getSignOwner(certId, signDate) {
        const binds = {
            P_CERT_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: certId },
            P_SIGN_DATE: { type: oracledb.DATE, dir: oracledb.BIND_IN, val: new Date(signDate) },
            P_USER_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT, maxSize: 200 },
            P_LEGAL_ID: { type: oracledb.STRING, dir: oracledb.BIND_OUT, maxSize: 20 }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN ${this.packageName}.signOwner(:P_CERT_ID, :P_SIGN_DATE, :P_USER_NAME, :P_LEGAL_ID); END;`,
                binds
            );

            return {
                userName: result.outBinds.P_USER_NAME,
                legalId: result.outBinds.P_LEGAL_ID,
                certificateId: certId,
                signatureDate: signDate
            };
        } finally {
            await connection.close();
        }
    }

    // 7. Get addresses
    async getAddresses(documentId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_CURSOR: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        };
        return await this.executeProcedure('get_addr', binds);
    }

    // 8. Get extensions
    async getExtensions(documentId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_CURSOR: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        };
        return await this.executeProcedure('get_extensions', binds);
    }

    // 9. Get IB signatures
    async getIBSignatures(documentId) {
        const binds = {
            P_DOC_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_CURSOR: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        };
        return await this.executeProcedure('get_ib_signatures', binds);
    }

    // 10. Enable manual processing
    async setManualProcessing(documentId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_RESULT: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
        };

        const result = await this.executeQuery(
            `BEGIN :P_RESULT := ${this.packageName}.set_ManualProcessing(:P_ID); END;`,
            binds
        );

        return {
            success: result.outBinds.P_RESULT === 0,
            documentId: documentId,
            manualProcessingEnabled: true
        };
    }

    // 11. Get change officer ID
    async getChangeOfficerId(documentId) {
        const binds = {
            P_ID: { type: oracledb.STRING, dir: oracledb.BIND_IN, val: documentId },
            P_RESULT: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
        };

        const result = await this.executeQuery(
            `BEGIN :P_RESULT := ${this.packageName}.getChangeOfficerId(:P_ID); END;`,
            binds
        );

        return {
            documentId: documentId,
            changeOfficerId: result.outBinds.P_RESULT
        };
    }

    // 12. Get by ID
    async getById(documentId) {
        const binds = {
            P_ID: { type: oracledb.NUMBER, dir: oracledb.BIND_IN, val: parseInt(documentId) },
            P_STATUS: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_OFFICER_ID: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_ITC: { type: oracledb.STRING, dir: oracledb.BIND_OUT, maxSize: 4000 },
            P_RESULT: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_RESULT := ${this.packageName}.get_by_id(:P_ID, :P_STATUS, :P_OFFICER_ID, :P_ITC); END;`,
                binds
            );

            return {
                id: documentId,
                status: result.outBinds.P_STATUS,
                officerId: result.outBinds.P_OFFICER_ID,
                infoToCustomer: result.outBinds.P_ITC,
                found: result.outBinds.P_RESULT === 0
            };
        } finally {
            await connection.close();
        }
    }
}

module.exports = DocumentsService;
```

### Step 2: Create MockDocumentsService.js

See next file...

---

## API Endpoints

```
GET    /api/documents/:id                    -> getById()
GET    /api/documents/:id/history            -> getHistory()
GET    /api/documents/:id/messages           -> getMessageHistory()
GET    /api/documents/:id/addresses          -> getAddresses()
GET    /api/documents/:id/extensions         -> getExtensions()
GET    /api/documents/:id/signatures         -> getIBSignatures()
GET    /api/documents/:id/change-officer     -> getChangeOfficerId()

POST   /api/documents/:id/lock               -> setLock()
POST   /api/documents/:id/status             -> setManualStatus()
POST   /api/documents/:id/status-with-ref    -> setManualStatusWithRef()
POST   /api/documents/:id/manual-processing  -> setManualProcessing()
POST   /api/documents/sign-owner             -> getSignOwner()
```

## Testing Strategy

1. **Mock Mode First** - Implement all mock methods with realistic data
2. **Unit Tests** - Test each service method independently
3. **Integration Tests** - Test with real Oracle DB
4. **Edge Cases** - Test with invalid IDs, locked documents, etc.

---

**Next:** Implement MockDocumentsService with comprehensive mock data matching the Oracle types structure.