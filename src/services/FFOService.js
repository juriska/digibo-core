const oracledb = require('oracledb');

const BaseService = require('./BaseService');

class FFOService extends BaseService {
    constructor() {
        super('FFO');
    }

    async getDocumentsList(classId, status) {
        const binds = {
            P_CLASS_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: classId
            },
            P_STATUS: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: status
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('getDocuments', binds);
    }

    async getAllDocuments() {
        const sql = `SELECT 1 FROM dual`;

        return await this.executeQuery(sql);
    }
}

module.exports = FFOService; 