const MockBaseService = require('./MockBaseService');
const { mockPaymentDocuments } = require('./mockData');

class MockPaymentService extends MockBaseService {
    constructor() {
        super('DocumentsPackage');
    }

    async getDocumentsList(classId, user) {
        console.log(`[MOCK MODE] Payment.getDocumentsList called with classId: ${classId}, user: ${user}`);

        // Filter mock data based on parameters
        let results = mockPaymentDocuments;

        if (classId) {
            results = results.filter(doc => doc.CLASS_ID === classId);
        }

        if (user) {
            results = results.filter(doc => doc.USER === user);
        }

        console.log(`[MOCK MODE] Returning ${results.length} payment documents`);
        return results;
    }
}

module.exports = MockPaymentService;