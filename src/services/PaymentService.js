const oracledb = require('oracledb');

const BaseService = require('./BaseService');

class PaymentService extends BaseService {
    constructor() {
        super('BOPayment');
    }

    async getDocumentsList(classId, user) {
        // Note: BOPayment doesn't have a getDocuments procedure
        // Using the find function instead which returns a cursor
        // This is a placeholder - actual implementation needs proper parameters for the find function
        console.log('[PaymentService] getDocumentsList not implemented - BOPayment.find requires many parameters');
        return [];
    }
}

module.exports = PaymentService;