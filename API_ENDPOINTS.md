# DigiBo Core API - Endpoints Documentation

## Base URL

```
http://localhost:3000/api
```

## Available Packages

- ✅ **BO_FFO** - Foreign Exchange Orders (Partial)
- ✅ **BO_PAYMENT** - Payments (Partial)
- ✅ **BO_DOCUMENTS** - Document Management (Complete - 12 endpoints)
- ⏳ **BO_CUSTOMER** - Customer Management (Planned)
- ⏳ **BO_AUDITLOG** - Audit Logging (Planned)
- ⏳ **BO_HELPDESK** - Help Desk (Planned)
- ⏳ **BO_SMSAGREEMENT** - SMS Services (Planned)

---

## BO_DOCUMENTS Endpoints

### 1. Get Document by ID

**GET** `/api/documents/:id`

Get basic document information.

**Parameters:**
- `id` (path) - Document ID

**Response:**
```json
{
  "id": "1",
  "status": 3,
  "officerId": 100,
  "infoToCustomer": "Document processed successfully",
  "found": true
}
```

**Status Codes:**
- `200` - Success
- `404` - Document not found
- `500` - Server error

---

### 2. Get Document History

**GET** `/api/documents/:id/history`

Get audit log history for a document.

**Parameters:**
- `id` (path) - Document ID

**Response:**
```json
[
  {
    "ID": 1001,
    "EVENT_TYPE_ID": 45,
    "TIMESTAMP": "2025-11-10T10:05:00Z",
    "STATUS": 1,
    "OFFICER": "John Smith",
    "DETAILS": "Document created"
  },
  {
    "ID": 1002,
    "EVENT_TYPE_ID": 46,
    "TIMESTAMP": "2025-11-10T11:30:00Z",
    "STATUS": 2,
    "OFFICER": "Jane Doe",
    "DETAILS": "Document reviewed"
  }
]
```

---

### 3. Get Message History

**GET** `/api/documents/:id/messages`

Get message-related history for a document.

**Parameters:**
- `id` (path) - Message ID

**Response:**
```json
[
  {
    "ID": 5001,
    "EVENT_TYPE_ID": 120,
    "TIMESTAMP": "2025-11-11T10:00:00Z",
    "STATUS": 1,
    "DETAILS": "Message received from customer"
  }
]
```

---

### 4. Get Document Addresses

**GET** `/api/documents/:id/addresses`

Get delivery addresses for a document.

**Parameters:**
- `id` (path) - Document ID

**Response:**
```json
[
  {
    "TYPE_ID": 1,
    "RECEIVING_TYPE": "MAIL",
    "BANK_OFFICE_NAME": "Main Branch",
    "ADDR": "LV-1050, LV, Riga, Brivibas street, 123, 45"
  }
]
```

---

### 5. Get Document Extensions

**GET** `/api/documents/:id/extensions`

Get document extensions/additional information.

**Parameters:**
- `id` (path) - Document ID

**Response:**
```json
[
  {
    "DICTIONARY_ID": 1001,
    "ADDITIONAL_INFO": "Extra verification required",
    "BLOCK_NUMBER": 1
  },
  {
    "DICTIONARY_ID": 1002,
    "ADDITIONAL_INFO": "Compliance check passed",
    "BLOCK_NUMBER": 2
  }
]
```

---

### 6. Get Document Signatures

**GET** `/api/documents/:id/signatures`

Get Internet Banking signatures for a document.

**Parameters:**
- `id` (path) - Document ID

**Response:**
```json
[
  {
    "NAME": "John Doe",
    "SIGNATURE_ACTION": "APPROVE",
    "SIGNATURE_LEVEL": 2,
    "SIGNATURE_DATE": "2025-11-10T11:00:00Z",
    "SIGNATURE_CDEVICE_TYPE_ID": 5,
    "SIGNATURE_CDEVICE_SERIAL": "DEVICE_ABC123",
    "DOCUMENT_BATCH_ID": 98765
  }
]
```

---

### 7. Get Change Officer

**GET** `/api/documents/:id/change-officer`

Get the officer who last changed the document.

**Parameters:**
- `id` (path) - Document ID

**Response:**
```json
{
  "documentId": "1",
  "changeOfficerId": 105
}
```

---

### 8. Lock Document

**POST** `/api/documents/:id/lock`

Lock a document for editing to prevent concurrent modifications.

**Parameters:**
- `id` (path) - Document ID

**Response (Success):**
```json
{
  "lockAcquired": true,
  "status": 3,
  "lockedBy": null,
  "message": "Document locked successfully"
}
```

**Response (Already Locked):**
```json
{
  "lockAcquired": false,
  "status": 3,
  "lockedBy": {
    "name": "Officer Jane Smith",
    "phone": "+371 67 123456"
  },
  "message": "Document is locked by another user"
}
```

**Status Codes:**
- `200` - Lock acquired
- `423` - Locked (document locked by another user)
- `500` - Server error

---

### 9. Set Document Status

**POST** `/api/documents/:id/status`

Manually set document status with reason.

**Parameters:**
- `id` (path) - Document ID

**Request Body:**
```json
{
  "reason": "Approved after verification",
  "newStatus": 5,
  "messageId": 9876
}
```

**Response:**
```json
{
  "success": true,
  "documentId": "1",
  "newStatus": 5,
  "message": "Document status updated successfully"
}
```

**Status Codes:**
- `200` - Success
- `400` - Missing required fields
- `500` - Server error

---

### 10. Set Document Status with Bank Reference

**POST** `/api/documents/:id/status-with-ref`

Set document status with bank reference number.

**Parameters:**
- `id` (path) - Document ID

**Request Body:**
```json
{
  "reason": "Processed in core banking",
  "newStatus": 10,
  "messageId": 9876,
  "bankReference": "GLOBUS/2025/12345"
}
```

**Response:**
```json
{
  "success": true,
  "documentId": "1",
  "newStatus": 10,
  "bankReference": "GLOBUS/2025/12345",
  "message": "Document status updated successfully with bank reference"
}
```

---

### 11. Enable Manual Processing

**POST** `/api/documents/:id/manual-processing`

Enable manual processing mode for a document.

**Parameters:**
- `id` (path) - Document ID

**Response:**
```json
{
  "success": true,
  "documentId": "1",
  "manualProcessingEnabled": true,
  "message": "Manual processing enabled"
}
```

---

### 12. Get Signature Owner

**POST** `/api/documents/sign-owner`

Get information about who owns a certificate/signature.

**Request Body:**
```json
{
  "certificateId": "CERT_ABC123",
  "signatureDate": "2025-11-10T11:00:00Z"
}
```

**Response:**
```json
{
  "userName": "John Doe",
  "legalId": "123456-12345",
  "certificateId": "CERT_ABC123",
  "signatureDate": "2025-11-10T11:00:00Z"
}
```

---

## BO_FFO Endpoints (Partial)

### 1. Get FFO Document List

**GET** `/api/ffo/documents/getList`

Get list of FFO documents with default filters.

**Response:**
```json
[
  {
    "ID": 1,
    "DOC_NUMBER": "FFO-2024-001",
    "CLASS_ID": 1,
    "STATUS": "NEW",
    "CUSTOMER_NAME": "John Doe",
    "AMOUNT": 5000,
    "CURRENCY": "EUR"
  }
]
```

---

### 2. Search FFO Documents

**POST** `/api/ffo/documents/getList`

Search FFO documents with custom parameters.

**Request Body:**
```json
{
  "classId": 1,
  "user": "NEW"
}
```

---

### 3. Get All FFO Documents

**GET** `/api/ffo/documents/all`

Get all FFO documents without filters.

---

## BO_PAYMENT Endpoints (Partial)

### 1. Get Payment Document List

**GET** `/api/payments/documents/getList`

Get list of payment documents.

---

### 2. Search Payment Documents

**POST** `/api/payments/documents/getList`

Search payment documents with filters.

**Request Body:**
```json
{
  "classId": 10,
  "user": "admin"
}
```

---

### 3. Get Draft Count

**GET** `/api/payments/documents/getDraftCount`

Get count of draft payment documents.

**Response:**
```json
{
  "count": 2
}
```

---

## Error Responses

All endpoints may return these error responses:

### 400 Bad Request
```json
{
  "error": "Bad Request",
  "message": "Missing required fields",
  "required": ["field1", "field2"]
}
```

### 404 Not Found
```json
{
  "error": "Document not found",
  "documentId": "123"
}
```

### 423 Locked
```json
{
  "lockAcquired": false,
  "lockedBy": {
    "name": "Officer Name",
    "phone": "+123456789"
  },
  "message": "Resource is locked"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

In development mode, errors may include additional details:
```json
{
  "error": "Internal server error",
  "message": "Detailed error message",
  "stack": "Error stack trace..."
}
```

---

## Testing with cURL

### Get Document
```bash
curl http://localhost:3000/api/documents/1
```

### Get Document History
```bash
curl http://localhost:3000/api/documents/1/history
```

### Lock Document
```bash
curl -X POST http://localhost:3000/api/documents/1/lock
```

### Set Document Status
```bash
curl -X POST http://localhost:3000/api/documents/1/status \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Approved",
    "newStatus": 5,
    "messageId": 100
  }'
```

### Get Signature Owner
```bash
curl -X POST http://localhost:3000/api/documents/sign-owner \
  -H "Content-Type: application/json" \
  -d '{
    "certificateId": "CERT_ABC123",
    "signatureDate": "2025-11-10T11:00:00Z"
  }'
```

---

## Authentication

Currently, the API does not require authentication in development mode. In production, endpoints should be protected with appropriate authentication mechanisms.

---

## Rate Limiting

No rate limiting is currently implemented. Consider adding rate limiting in production.

---

## CORS

The API is configured to accept requests from:
- `https://preview--digi-backstage-haven.lovable.app`
- `http://localhost:3000`
- `http://localhost:5173`

---

## Mock Mode

When `MOCK_ENABLED=true`, all endpoints return mock data without connecting to the Oracle database.

To enable mock mode:
```bash
npm run dev:mock
```

Or set environment variable:
```bash
MOCK_ENABLED=true npm start
```

---

**Last Updated:** 2025-11-11
**API Version:** 0.1.0