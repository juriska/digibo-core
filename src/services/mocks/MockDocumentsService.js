const MockBaseService = require('./MockBaseService');
const {
    mockDocumentHistory,
    mockMessageHistory,
    mockDocumentAddresses,
    mockDocumentExtensions,
    mockDocumentSignatures,
    mockDocuments
} = require('./mockData');

class MockDocumentsService extends MockBaseService {
    constructor() {
        super('BODocuments');
    }

    /**
     * Get document audit history
     * Returns helpdesk_log_t type
     */
    async getHistory(documentId) {
        console.log(`[MOCK MODE] BODocuments.history(${documentId})`);

        // Filter by sessionId or just return all for demo (Oracle would filter by document)
        const history = mockDocumentHistory;
        console.log(`[MOCK MODE] Returning ${history.length} history entries`);

        // Return directly - Oracle returns rows matching helpdesk_log_t structure
        return history;
    }

    /**
     * Get message-related history
     */
    async getMessageHistory(documentId) {
        console.log(`[MOCK MODE] BODocuments.messageHistory(${documentId})`);

        const history = mockMessageHistory.filter(h => h.MESSAGE_ID === documentId);
        console.log(`[MOCK MODE] Returning ${history.length} message history entries`);

        return history.map(h => ({
            ID: h.ID,
            EVENT_TYPE_ID: h.EVENT_TYPE_ID,
            TIMESTAMP: h.TIMESTAMP,
            STATUS: h.STATUS,
            DETAILS: h.DETAILS
        }));
    }

    /**
     * Lock document for editing
     */
    async setLock(documentId) {
        console.log(`[MOCK MODE] BODocuments.set_lock(${documentId})`);

        const doc = mockDocuments.find(d => d.ID === documentId);

        if (!doc) {
            return {
                lockAcquired: false,
                status: null,
                lockedBy: null,
                error: 'Document not found'
            };
        }

        // Simulate: 20% chance document is locked by another user
        const isLocked = Math.random() < 0.2;

        if (isLocked) {
            return {
                lockAcquired: false,
                status: doc.STATUS_ID,
                lockedBy: {
                    name: 'Officer Jane Smith',
                    phone: '+371 67 123456'
                }
            };
        }

        return {
            lockAcquired: true,
            status: doc.STATUS_ID,
            lockedBy: null
        };
    }

    /**
     * Set document status manually
     */
    async setManualStatus(documentId, reason, newStatus, messageId) {
        console.log(`[MOCK MODE] BODocuments.set_manual_status(${documentId}, ${reason}, ${newStatus}, ${messageId})`);

        const doc = mockDocuments.find(d => d.ID === documentId);

        if (doc) {
            doc.STATUS_ID = newStatus;
            doc.INFO_TO_CUSTOMER = reason;
            doc.LAST_UPDATE_DATE = new Date().toISOString();
        }

        return {
            success: true,
            documentId: documentId,
            newStatus: newStatus
        };
    }

    /**
     * Set document status manually with bank reference
     */
    async setManualStatusWithRef(documentId, reason, newStatus, messageId, bankReference) {
        console.log(`[MOCK MODE] BODocuments.set_manual_status_1(${documentId}, ${reason}, ${newStatus}, ${messageId}, ${bankReference})`);

        const doc = mockDocuments.find(d => d.ID === documentId);

        if (doc) {
            doc.STATUS_ID = newStatus;
            doc.INFO_TO_CUSTOMER = reason;
            doc.BANK_REFERENCE = bankReference;
            doc.LAST_UPDATE_DATE = new Date().toISOString();
        }

        return {
            success: true,
            documentId: documentId,
            newStatus: newStatus,
            bankReference: bankReference
        };
    }

    /**
     * Get signature owner information
     */
    async getSignOwner(certId, signDate) {
        console.log(`[MOCK MODE] BODocuments.signOwner(${certId}, ${signDate})`);

        // Mock signature owners based on cert ID
        const mockOwners = {
            'CERT_ABC123': { userName: 'John Doe', legalId: '123456-12345' },
            'CERT_XYZ789': { userName: 'Jane Smith', legalId: '654321-54321' },
            'CERT_DEFAULT': { userName: 'Test User', legalId: '111111-11111' }
        };

        const owner = mockOwners[certId] || mockOwners['CERT_DEFAULT'];

        return {
            userName: owner.userName,
            legalId: owner.legalId,
            certificateId: certId,
            signatureDate: signDate
        };
    }

    /**
     * Get document addresses
     */
    async getAddresses(documentId) {
        console.log(`[MOCK MODE] BODocuments.get_addr(${documentId})`);

        const addresses = mockDocumentAddresses.filter(a => a.DOCUMENT_ID === documentId);
        console.log(`[MOCK MODE] Returning ${addresses.length} addresses`);

        return addresses.map(a => ({
            TYPE_ID: a.TYPE_ID,
            RECEIVING_TYPE: a.RECEIVING_TYPE,
            BANK_OFFICE_NAME: a.BANK_OFFICE_NAME,
            ADDR: a.ADDR
        }));
    }

    /**
     * Get document extensions
     */
    async getExtensions(documentId) {
        console.log(`[MOCK MODE] BODocuments.get_extensions(${documentId})`);

        const extensions = mockDocumentExtensions.filter(e => e.DOCUMENT_ID === documentId);
        console.log(`[MOCK MODE] Returning ${extensions.length} extensions`);

        return extensions.map(e => ({
            DICTIONARY_ID: e.DICTIONARY_ID,
            ADDITIONAL_INFO: e.ADDITIONAL_INFO,
            BLOCK_NUMBER: e.BLOCK_NUMBER
        }));
    }

    /**
     * Get Internet Banking signatures
     */
    async getIBSignatures(documentId) {
        console.log(`[MOCK MODE] BODocuments.get_ib_signatures(${documentId})`);

        const signatures = mockDocumentSignatures.filter(s => s.DOCUMENT_ID === documentId);
        console.log(`[MOCK MODE] Returning ${signatures.length} signatures`);

        return signatures.map(s => ({
            NAME: s.NAME,
            SIGNATURE_ACTION: s.SIGNATURE_ACTION,
            SIGNATURE_LEVEL: s.SIGNATURE_LEVEL,
            SIGNATURE_DATE: s.SIGNATURE_DATE,
            SIGNATURE_CDEVICE_TYPE_ID: s.SIGNATURE_CDEVICE_TYPE_ID,
            SIGNATURE_CDEVICE_SERIAL: s.SIGNATURE_CDEVICE_SERIAL,
            DOCUMENT_BATCH_ID: s.DOCUMENT_BATCH_ID
        }));
    }

    /**
     * Enable manual processing
     */
    async setManualProcessing(documentId) {
        console.log(`[MOCK MODE] BODocuments.set_ManualProcessing(${documentId})`);

        const doc = mockDocuments.find(d => d.ID === documentId);

        if (doc) {
            doc.MANUAL_PROCESSING = true;
        }

        return {
            success: true,
            documentId: documentId,
            manualProcessingEnabled: true
        };
    }

    /**
     * Get change officer ID
     */
    async getChangeOfficerId(documentId) {
        console.log(`[MOCK MODE] BODocuments.getChangeOfficerId(${documentId})`);

        const doc = mockDocuments.find(d => d.ID === documentId);

        const changeOfficerId = doc ? doc.CHANGE_OFFICER_ID || 7890 : null;

        return {
            documentId: documentId,
            changeOfficerId: changeOfficerId
        };
    }

    /**
     * Get document by ID
     */
    async getById(documentId) {
        console.log(`[MOCK MODE] BODocuments.get_by_id(${documentId})`);

        const doc = mockDocuments.find(d => d.ID === parseInt(documentId));

        if (!doc) {
            return {
                id: documentId,
                status: null,
                officerId: null,
                infoToCustomer: null,
                found: false
            };
        }

        return {
            id: documentId,
            status: doc.STATUS_ID,
            officerId: doc.OFFICER_ID || 100,
            infoToCustomer: doc.INFO_TO_CUSTOMER || '',
            found: true
        };
    }
}

module.exports = MockDocumentsService;