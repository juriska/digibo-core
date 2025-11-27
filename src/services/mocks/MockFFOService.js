const MockBaseService = require('./MockBaseService');
const { mockFFODocuments } = require('./mockData');

class MockFFOService extends MockBaseService {
    constructor() {
        super('BOFFO');
    }

    async findMy() {
        console.log(`[MOCK MODE] BOFFO.find_my() called`);
        console.log(`[MOCK MODE] Returning ${mockFFODocuments.length} FFO documents`);
        return mockFFODocuments;
    }

    async getById(documentId) {
        console.log(`[MOCK MODE] Getting FFO document by ID: ${documentId}`);
        const doc = mockFFODocuments.find(d => d.ID == documentId);
        return doc || null;
    }

    async getCategories() {
        console.log(`[MOCK MODE] BOFFO.get_categories() called`);
        // Mock categories
        return [
            {
                ID: 201,
                NAME: 'Currency Exchange',
                PARENT_ID: null
            },
            {
                ID: 202,
                NAME: 'General Inquiry',
                PARENT_ID: null
            },
            {
                ID: 301,
                NAME: 'EUR to USD',
                PARENT_ID: 201
            },
            {
                ID: 302,
                NAME: 'EUR to GBP',
                PARENT_ID: 201
            },
            {
                ID: 303,
                NAME: 'Payment Information',
                PARENT_ID: 202
            }
        ];
    }

    async categorize(docId, categoryId, subCategoryId, assignee) {
        console.log(`[MOCK MODE] BOFFO.categorize(${docId}, ${categoryId}, ${subCategoryId}, ${assignee})`);

        const doc = mockFFODocuments.find(d => d.ID == docId);
        if (doc) {
            doc.CATEGORY_ID = categoryId;
            doc.SUBCATEGORY_ID = subCategoryId;
            doc.ASSIGNEE = assignee;
        }

        return {
            success: true,
            documentId: docId,
            categoryId,
            subCategoryId,
            assignee,
            result: 0
        };
    }

    async setProcessing(docId, reason, newStatus, messageId) {
        console.log(`[MOCK MODE] BOFFO.set_processing(${docId}, ${reason}, ${newStatus}, ${messageId})`);

        const doc = mockFFODocuments.find(d => d.ID == docId);
        if (doc) {
            doc.STATUS_ID = newStatus;
        }

        return {
            success: true,
            documentId: docId,
            newStatus,
            result: 0
        };
    }
}

module.exports = MockFFOService;