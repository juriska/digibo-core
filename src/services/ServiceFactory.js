// Service factory to switch between mock and real services based on environment

const mockEnabled = process.env.MOCK_ENABLED === 'true';

console.log(`[SERVICE FACTORY] Mock mode: ${mockEnabled ? 'ENABLED' : 'DISABLED'}`);

// Import real services
const FFOService = require('./FFOService');
const PaymentService = require('./PaymentService');
const DocumentsService = require('./DocumentsService');
const CustomerService = require('./CustomerService');
const AuditLogService = require('./AuditLogService');

// Import mock services
const MockFFOService = require('./mocks/MockFFOService');
const MockPaymentService = require('./mocks/MockPaymentService');
const MockDocumentsService = require('./mocks/MockDocumentsService');
const MockCustomerService = require('./mocks/MockCustomerService');
const MockAuditLogService = require('./mocks/MockAuditLogService');

// Export the appropriate service based on environment
module.exports = {
    FFOService: mockEnabled ? MockFFOService : FFOService,
    PaymentService: mockEnabled ? MockPaymentService : PaymentService,
    DocumentsService: mockEnabled ? MockDocumentsService : DocumentsService,
    CustomerService: mockEnabled ? MockCustomerService : CustomerService,
    AuditLogService: mockEnabled ? MockAuditLogService : AuditLogService
};