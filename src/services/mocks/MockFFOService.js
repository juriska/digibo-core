const MockBaseService = require('./MockBaseService');
const { mockFFODocuments } = require('./mockData');

class MockFFOService extends MockBaseService {
    constructor() {
        super('FFO');
    }

    async getDocumentsList(classId, status) {
        console.log(`[MOCK MODE] FFO.getDocumentsList called with classId: ${classId}, status: ${status}`);

        // Filter mock data based on parameters
        let results = mockFFODocuments;

        if (classId) {
            results = results.filter(doc => doc.CLASS_ID === classId);
        }

        if (status) {
            results = results.filter(doc => doc.STATUS === status);
        }

        console.log(`[MOCK MODE] Returning ${results.length} documents`);
        return results;
    }

    async getAllDocuments() {
        console.log('[MOCK MODE] FFO.getAllDocuments called');
        console.log(`[MOCK MODE] Returning ${mockFFODocuments.length} documents`);
        return mockFFODocuments;
    }
}

module.exports = MockFFOService;