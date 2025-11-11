const oracledb = require('oracledb');

const BaseService = require('./BaseService');

class PaymentService extends BaseService {
    constructor() {
        super('DocumentsPackage');
    }

    async getDocumentsList(classId, user) {
        const binds = {
            P_CLASS_IDS: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: classId
            },
            P_USER: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: user
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('getDocuments', binds);
    }
}

module.exports = PaymentService;