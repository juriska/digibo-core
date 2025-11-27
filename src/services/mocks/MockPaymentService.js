const MockBaseService = require('./MockBaseService');
const { mockPaymentDocuments } = require('./mockData');

class MockPaymentService extends MockBaseService {
    constructor() {
        super('BOPayment');
    }

    async getDocumentsList(classId, user) {
        console.log(`[MOCK MODE] BOPayment.find (not fully implemented)`);

        // Return mock data matching payment_t structure
        // Note: BOPayment.find() requires many parameters - this is simplified
        const results = mockPaymentDocuments;

        console.log(`[MOCK MODE] Returning ${results.length} payment documents`);
        return results;
    }
}

module.exports = MockPaymentService;