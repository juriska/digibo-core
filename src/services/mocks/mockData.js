// Mock data for local development

const mockFFODocuments = [
  {
    ID: 1,
    DOC_NUMBER: 'FFO-2024-001',
    CLASS_ID: 1,
    STATUS: 'NEW',
    CUSTOMER_NAME: 'John Doe',
    CUSTOMER_ID: 'C001',
    AMOUNT: 5000,
    CURRENCY: 'EUR',
    CREATED_DATE: '2024-01-15',
    UPDATED_DATE: '2024-01-15',
    DESCRIPTION: 'Foreign exchange order'
  },
  {
    ID: 2,
    DOC_NUMBER: 'FFO-2024-002',
    CLASS_ID: 1,
    STATUS: 'APPROVED',
    CUSTOMER_NAME: 'Jane Smith',
    CUSTOMER_ID: 'C002',
    AMOUNT: 10000,
    CURRENCY: 'USD',
    CREATED_DATE: '2024-01-16',
    UPDATED_DATE: '2024-01-17',
    DESCRIPTION: 'Currency exchange transaction'
  },
  {
    ID: 3,
    DOC_NUMBER: 'FFO-2024-003',
    CLASS_ID: 2,
    STATUS: 'NEW',
    CUSTOMER_NAME: 'Bob Wilson',
    CUSTOMER_ID: 'C003',
    AMOUNT: 7500,
    CURRENCY: 'GBP',
    CREATED_DATE: '2024-01-18',
    UPDATED_DATE: '2024-01-18',
    DESCRIPTION: 'International transfer'
  }
];

const mockPaymentDocuments = [
  {
    ID: 101,
    DOC_NUMBER: 'PAY-2024-001',
    CLASS_ID: 10,
    CUSTOMER_NAME: 'Alice Johnson',
    CUSTOMER_ID: 'C004',
    AMOUNT: 2500,
    CURRENCY: 'EUR',
    STATUS: 'PENDING',
    PAYMENT_TYPE: 'SEPA',
    CREATED_DATE: '2024-01-15',
    DUE_DATE: '2024-01-25',
    USER: 'admin'
  },
  {
    ID: 102,
    DOC_NUMBER: 'PAY-2024-002',
    CLASS_ID: 10,
    CUSTOMER_NAME: 'Charlie Brown',
    CUSTOMER_ID: 'C005',
    AMOUNT: 8000,
    CURRENCY: 'USD',
    STATUS: 'COMPLETED',
    PAYMENT_TYPE: 'SWIFT',
    CREATED_DATE: '2024-01-16',
    DUE_DATE: '2024-01-20',
    USER: 'admin'
  },
  {
    ID: 103,
    DOC_NUMBER: 'PAY-2024-003',
    CLASS_ID: 11,
    CUSTOMER_NAME: 'Diana Prince',
    CUSTOMER_ID: 'C006',
    AMOUNT: 3500,
    CURRENCY: 'EUR',
    STATUS: 'PENDING',
    PAYMENT_TYPE: 'SEPA',
    CREATED_DATE: '2024-01-19',
    DUE_DATE: '2024-01-30',
    USER: 'user1'
  }
];

// Mock documents (generic documents table data)
const mockDocuments = [
  {
    ID: 1,
    DOC_NUMBER: 'DOC-2025-001',
    CLASS_ID: 1,
    STATUS_ID: 3,
    ORDER_DATE: '2025-11-10T10:00:00Z',
    CREATOR_CHANNEL_ID: 5,
    INFO_TO_CUSTOMER: 'Document processed successfully',
    OFFICER_ID: 100,
    CHANGE_OFFICER_ID: 105,
    LAST_UPDATE_DATE: '2025-11-11T14:00:00Z'
  },
  {
    ID: 2,
    DOC_NUMBER: 'DOC-2025-002',
    CLASS_ID: 10,
    STATUS_ID: 1,
    ORDER_DATE: '2025-11-11T09:00:00Z',
    CREATOR_CHANNEL_ID: 5,
    INFO_TO_CUSTOMER: 'Awaiting approval',
    OFFICER_ID: 101,
    CHANGE_OFFICER_ID: 106,
    LAST_UPDATE_DATE: '2025-11-11T09:30:00Z'
  },
  {
    ID: 3,
    DOC_NUMBER: 'DOC-2025-003',
    CLASS_ID: 25,
    STATUS_ID: 5,
    ORDER_DATE: '2025-11-09T14:00:00Z',
    CREATOR_CHANNEL_ID: 28,
    INFO_TO_CUSTOMER: 'Completed',
    OFFICER_ID: 102,
    CHANGE_OFFICER_ID: 107,
    BANK_REFERENCE: 'GLOBUS/2025/12345',
    LAST_UPDATE_DATE: '2025-11-10T16:00:00Z'
  }
];

// Mock document history (audit log)
const mockDocumentHistory = [
  {
    ID: 1001,
    DOCUMENT_ID: 1,
    EVENT_TYPE_ID: 45,
    TIMESTAMP: '2025-11-10T10:05:00Z',
    STATUS: 1,
    OFFICER: 'John Smith',
    DETAILS: 'Document created'
  },
  {
    ID: 1002,
    DOCUMENT_ID: 1,
    EVENT_TYPE_ID: 46,
    TIMESTAMP: '2025-11-10T11:30:00Z',
    STATUS: 2,
    OFFICER: 'Jane Doe',
    DETAILS: 'Document reviewed'
  },
  {
    ID: 1003,
    DOCUMENT_ID: 1,
    EVENT_TYPE_ID: 47,
    TIMESTAMP: '2025-11-11T14:00:00Z',
    STATUS: 3,
    OFFICER: 'John Smith',
    DETAILS: 'Document approved'
  },
  {
    ID: 2001,
    DOCUMENT_ID: 2,
    EVENT_TYPE_ID: 45,
    TIMESTAMP: '2025-11-11T09:00:00Z',
    STATUS: 1,
    OFFICER: 'Alice Johnson',
    DETAILS: 'Document submitted'
  },
  {
    ID: 3001,
    DOCUMENT_ID: 3,
    EVENT_TYPE_ID: 47,
    TIMESTAMP: '2025-11-09T15:00:00Z',
    STATUS: 5,
    OFFICER: 'Bob Wilson',
    DETAILS: 'Document processed in core banking'
  }
];

// Mock message history
const mockMessageHistory = [
  {
    ID: 5001,
    MESSAGE_ID: 9876,
    EVENT_TYPE_ID: 120,
    TIMESTAMP: '2025-11-11T10:00:00Z',
    STATUS: 1,
    DETAILS: 'Message received from customer'
  },
  {
    ID: 5002,
    MESSAGE_ID: 9876,
    EVENT_TYPE_ID: 121,
    TIMESTAMP: '2025-11-11T10:15:00Z',
    STATUS: 2,
    DETAILS: 'Message read by officer'
  },
  {
    ID: 5003,
    MESSAGE_ID: 9877,
    EVENT_TYPE_ID: 120,
    TIMESTAMP: '2025-11-11T11:00:00Z',
    STATUS: 1,
    DETAILS: 'New message from customer'
  }
];

// Mock document addresses
const mockDocumentAddresses = [
  {
    DOCUMENT_ID: 1,
    TYPE_ID: 1,
    RECEIVING_TYPE: 'MAIL',
    BANK_OFFICE_NAME: 'Main Branch',
    ADDR: 'LV-1050, LV, Riga, Brivibas street, 123, 45'
  },
  {
    DOCUMENT_ID: 1,
    TYPE_ID: 2,
    RECEIVING_TYPE: 'COURIER',
    BANK_OFFICE_NAME: 'Central Office',
    ADDR: 'LV-1010, LV, Riga, Elizabetes street, 67, 12'
  },
  {
    DOCUMENT_ID: 2,
    TYPE_ID: 1,
    RECEIVING_TYPE: 'EMAIL',
    BANK_OFFICE_NAME: 'Regional Branch',
    ADDR: 'LV-2000, LV, Jurmala, Jomas street, 45, 8'
  },
  {
    DOCUMENT_ID: 3,
    TYPE_ID: 1,
    RECEIVING_TYPE: 'MAIL',
    BANK_OFFICE_NAME: 'Downtown Branch',
    ADDR: 'LV-1050, LV, Riga, Gertrudes street, 15, 3'
  }
];

// Mock document extensions
const mockDocumentExtensions = [
  {
    DOCUMENT_ID: 1,
    DICTIONARY_ID: 1001,
    ADDITIONAL_INFO: 'Extra verification required',
    BLOCK_NUMBER: 1
  },
  {
    DOCUMENT_ID: 1,
    DICTIONARY_ID: 1002,
    ADDITIONAL_INFO: 'Compliance check passed',
    BLOCK_NUMBER: 2
  },
  {
    DOCUMENT_ID: 2,
    DICTIONARY_ID: 1003,
    ADDITIONAL_INFO: 'High priority customer',
    BLOCK_NUMBER: 1
  },
  {
    DOCUMENT_ID: 3,
    DICTIONARY_ID: 1001,
    ADDITIONAL_INFO: 'Standard processing',
    BLOCK_NUMBER: 1
  },
  {
    DOCUMENT_ID: 3,
    DICTIONARY_ID: 1005,
    ADDITIONAL_INFO: 'AML screening completed',
    BLOCK_NUMBER: 2
  }
];

// Mock IB signatures
const mockDocumentSignatures = [
  {
    DOCUMENT_ID: 1,
    NAME: 'John Doe',
    SIGNATURE_ACTION: 'APPROVE',
    SIGNATURE_LEVEL: 2,
    SIGNATURE_DATE: '2025-11-10T11:00:00Z',
    SIGNATURE_CDEVICE_TYPE_ID: 5,
    SIGNATURE_CDEVICE_SERIAL: 'DEVICE_ABC123',
    DOCUMENT_BATCH_ID: 98765
  },
  {
    DOCUMENT_ID: 1,
    NAME: 'Jane Smith',
    SIGNATURE_ACTION: 'VERIFY',
    SIGNATURE_LEVEL: 1,
    SIGNATURE_DATE: '2025-11-10T11:30:00Z',
    SIGNATURE_CDEVICE_TYPE_ID: 5,
    SIGNATURE_CDEVICE_SERIAL: 'DEVICE_XYZ789',
    DOCUMENT_BATCH_ID: 98765
  },
  {
    DOCUMENT_ID: 3,
    NAME: 'Bob Wilson',
    SIGNATURE_ACTION: 'APPROVE',
    SIGNATURE_LEVEL: 3,
    SIGNATURE_DATE: '2025-11-09T15:00:00Z',
    SIGNATURE_CDEVICE_TYPE_ID: 7,
    SIGNATURE_CDEVICE_SERIAL: 'DEVICE_MOBILE_001',
    DOCUMENT_BATCH_ID: 98766
  }
];

module.exports = {
  mockFFODocuments,
  mockPaymentDocuments,
  mockDocuments,
  mockDocumentHistory,
  mockMessageHistory,
  mockDocumentAddresses,
  mockDocumentExtensions,
  mockDocumentSignatures
};