// Mock data for local development
// Based on Oracle type definitions from bo_types.sql

// ffo_t type definition:
// id number(14), class_id number(4), status_id number(2), order_date date,
// document_number varchar2(16), creator_channel_id number(2), login varchar2(60),
// ff_subject varchar2(105), woc_id number(14), glb_cust_id number(10),
// sector number(5), segment varchar2(32), isDocumentAttached number(2),
// category_id number(9), subcategory_id number(9), category_name varchar2(50),
// subcategory_name varchar2(50), assignee number(9), document_attached number(1)
const mockFFODocuments = [
  {
    ID: 1,
    CLASS_ID: 101,
    STATUS_ID: 1,
    ORDER_DATE: new Date('2024-01-15T10:30:00Z'),
    DOCUMENT_NUMBER: 'FFO-2024-001',
    CREATOR_CHANNEL_ID: 5,
    LOGIN: 'john.doe',
    FF_SUBJECT: 'Request for foreign currency exchange',
    WOC_ID: 10001,
    GLB_CUST_ID: 5001,
    SECTOR: 100,
    SEGMENT: 'RETAIL',
    ISDOCUMENTATTACHED: 1,
    CATEGORY_ID: 201,
    SUBCATEGORY_ID: 301,
    CATEGORY_NAME: 'Currency Exchange',
    SUBCATEGORY_NAME: 'EUR to USD',
    ASSIGNEE: 7001,
    DOCUMENT_ATTACHED: 1
  },
  {
    ID: 2,
    CLASS_ID: 101,
    STATUS_ID: 3,
    ORDER_DATE: new Date('2024-01-16T14:00:00Z'),
    DOCUMENT_NUMBER: 'FFO-2024-002',
    CREATOR_CHANNEL_ID: 5,
    LOGIN: 'jane.smith',
    FF_SUBJECT: 'USD currency purchase request',
    WOC_ID: 10002,
    GLB_CUST_ID: 5002,
    SECTOR: 100,
    SEGMENT: 'CORPORATE',
    ISDOCUMENTATTACHED: 0,
    CATEGORY_ID: 201,
    SUBCATEGORY_ID: 302,
    CATEGORY_NAME: 'Currency Exchange',
    SUBCATEGORY_NAME: 'EUR to GBP',
    ASSIGNEE: 7002,
    DOCUMENT_ATTACHED: 0
  },
  {
    ID: 3,
    CLASS_ID: 102,
    STATUS_ID: 1,
    ORDER_DATE: new Date('2024-01-18T09:15:00Z'),
    DOCUMENT_NUMBER: 'FFO-2024-003',
    CREATOR_CHANNEL_ID: 28,
    LOGIN: 'bob.wilson',
    FF_SUBJECT: 'International payment inquiry',
    WOC_ID: 10003,
    GLB_CUST_ID: 5003,
    SECTOR: 200,
    SEGMENT: 'PRIVATE',
    ISDOCUMENTATTACHED: 1,
    CATEGORY_ID: 202,
    SUBCATEGORY_ID: 303,
    CATEGORY_NAME: 'General Inquiry',
    SUBCATEGORY_NAME: 'Payment Information',
    ASSIGNEE: 7001,
    DOCUMENT_ATTACHED: 1
  }
];

// payment_t type definition:
// id number(14), class_id number(3), status_id number(2), order_date date,
// document_number varchar2(16), creator_channel_id number(2), credit_amount varchar2(32),
// debit_amount varchar2(32), credit_ccy varchar2(3), debit_ccy varchar2(3),
// itb integer, login varchar2(60), woc_id number(10), sector number(5),
// segment varchar2(32), fromLocation varchar2(30)
const mockPaymentDocuments = [
  {
    ID: 101,
    CLASS_ID: 10,
    STATUS_ID: 1,
    ORDER_DATE: new Date('2024-01-15T10:00:00Z'),
    DOCUMENT_NUMBER: 'PAY-2024-001',
    CREATOR_CHANNEL_ID: 5,
    CREDIT_AMOUNT: '2500.00',
    DEBIT_AMOUNT: '2500.00',
    CREDIT_CCY: 'EUR',
    DEBIT_CCY: 'EUR',
    ITB: 45, // length of info_to_bank
    LOGIN: 'alice.johnson',
    WOC_ID: 20001,
    SECTOR: 100,
    SEGMENT: 'RETAIL',
    FROMLOCATION: 'LV'
  },
  {
    ID: 102,
    CLASS_ID: 10,
    STATUS_ID: 5,
    ORDER_DATE: new Date('2024-01-16T11:30:00Z'),
    DOCUMENT_NUMBER: 'PAY-2024-002',
    CREATOR_CHANNEL_ID: 5,
    CREDIT_AMOUNT: '8000.00',
    DEBIT_AMOUNT: '8000.00',
    CREDIT_CCY: 'USD',
    DEBIT_CCY: 'USD',
    ITB: 120,
    LOGIN: 'charlie.brown',
    WOC_ID: 20002,
    SECTOR: 200,
    SEGMENT: 'CORPORATE',
    FROMLOCATION: 'LV'
  },
  {
    ID: 103,
    CLASS_ID: 11,
    STATUS_ID: 1,
    ORDER_DATE: new Date('2024-01-19T09:00:00Z'),
    DOCUMENT_NUMBER: 'PAY-2024-003',
    CREATOR_CHANNEL_ID: 28,
    CREDIT_AMOUNT: '3500.00',
    DEBIT_AMOUNT: '3500.00',
    CREDIT_CCY: 'EUR',
    DEBIT_CCY: 'EUR',
    ITB: 60,
    LOGIN: 'diana.prince',
    WOC_ID: 20003,
    SECTOR: 100,
    SEGMENT: 'PRIVATE',
    FROMLOCATION: 'EE'
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

// helpdesk_log_t type definition (used by BODocuments.history):
// id number(14), eventId number(10), eventDate date, eventName varchar2(211),
// eventGroup varchar2(211), details varchar2(2000), officer varchar2(70),
// host varchar2(64), sessionId number(14)
const mockDocumentHistory = [
  {
    ID: 1001,
    EVENTID: 45,
    EVENTDATE: new Date('2025-11-10T10:05:00Z'),
    EVENTNAME: 'DOCUMENT_CREATED',
    EVENTGROUP: 'Document Lifecycle',
    DETAILS: 'Document created via Internet Banking',
    OFFICER: 'John Smith',
    HOST: '192.168.1.100',
    SESSIONID: 50001
  },
  {
    ID: 1002,
    EVENTID: 46,
    EVENTDATE: new Date('2025-11-10T11:30:00Z'),
    EVENTNAME: 'DOCUMENT_REVIEWED',
    EVENTGROUP: 'Document Lifecycle',
    DETAILS: 'Document reviewed and validated',
    OFFICER: 'Jane Doe',
    HOST: '192.168.1.105',
    SESSIONID: 50002
  },
  {
    ID: 1003,
    EVENTID: 47,
    EVENTDATE: new Date('2025-11-11T14:00:00Z'),
    EVENTNAME: 'DOCUMENT_APPROVED',
    EVENTGROUP: 'Document Lifecycle',
    DETAILS: 'Document approved for processing',
    OFFICER: 'John Smith',
    HOST: '192.168.1.100',
    SESSIONID: 50003
  },
  {
    ID: 2001,
    EVENTID: 45,
    EVENTDATE: new Date('2025-11-11T09:00:00Z'),
    EVENTNAME: 'DOCUMENT_CREATED',
    EVENTGROUP: 'Document Lifecycle',
    DETAILS: 'Document submitted by customer',
    OFFICER: 'Alice Johnson',
    HOST: '192.168.1.120',
    SESSIONID: 50004
  },
  {
    ID: 3001,
    EVENTID: 47,
    EVENTDATE: new Date('2025-11-09T15:00:00Z'),
    EVENTNAME: 'DOCUMENT_PROCESSED',
    EVENTGROUP: 'Document Lifecycle',
    DETAILS: 'Document processed in GLOBUS core banking system',
    OFFICER: 'Bob Wilson',
    HOST: '192.168.1.110',
    SESSIONID: 50005
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