const oracledb = require('oracledb');
const BaseService = require('./BaseService');
const { getConnection } = require('../config/database');

class DocumentsService extends BaseService {
    constructor() {
        super('BODocuments');
    }

    /**
     * Get document audit history
     * @param {string} documentId - Document ID
     * @returns {Promise<Array>} Array of audit log entries
     */
    async getHistory(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('history', binds);
    }

    /**
     * Get message-related history for a document
     * @param {string} documentId - Document/Message ID
     * @returns {Promise<Array>} Array of message history entries
     */
    async getMessageHistory(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('messageHistory', binds);
    }

    /**
     * Lock document for editing
     * @param {string} documentId - Document ID
     * @returns {Promise<Object>} Lock status and officer info if already locked
     */
    async setLock(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_STATUS: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            },
            P_OFFICER_NAME: {
                type: oracledb.STRING,
                dir: oracledb.BIND_OUT,
                maxSize: 200
            },
            P_OFFICER_PHONE: {
                type: oracledb.STRING,
                dir: oracledb.BIND_OUT,
                maxSize: 50
            },
            P_RESULT: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_RESULT := ${this.packageName}.set_lock(:P_ID, :P_STATUS, :P_OFFICER_NAME, :P_OFFICER_PHONE); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            return {
                lockAcquired: result.outBinds.P_RESULT === 0,
                status: result.outBinds.P_STATUS,
                lockedBy: result.outBinds.P_RESULT === 1 ? {
                    name: result.outBinds.P_OFFICER_NAME,
                    phone: result.outBinds.P_OFFICER_PHONE
                } : null
            };
        } finally {
            await connection.close();
        }
    }

    /**
     * Set document status manually
     * @param {string} documentId - Document ID
     * @param {string} reason - Reason for status change
     * @param {number} newStatus - New status ID
     * @param {number} messageId - Message ID for audit
     * @returns {Promise<Object>} Success indicator
     */
    async setManualStatus(documentId, reason, newStatus, messageId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_REASON: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: reason
            },
            P_NEW_STATUS: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: newStatus
            },
            P_MESSAGE_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: messageId
            }
        };

        const connection = await getConnection();
        try {
            await connection.execute(
                `BEGIN ${this.packageName}.set_manual_status(:P_ID, :P_REASON, :P_NEW_STATUS, :P_MESSAGE_ID); END;`,
                binds
            );

            return {
                success: true,
                documentId: documentId,
                newStatus: newStatus
            };
        } finally {
            await connection.close();
        }
    }

    /**
     * Set document status manually with bank reference
     * @param {string} documentId - Document ID
     * @param {string} reason - Reason for status change
     * @param {number} newStatus - New status ID
     * @param {number} messageId - Message ID for audit
     * @param {string} bankReference - Bank reference number
     * @returns {Promise<Object>} Success indicator
     */
    async setManualStatusWithRef(documentId, reason, newStatus, messageId, bankReference) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_REASON: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: reason
            },
            P_NEW_STATUS: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: newStatus
            },
            P_MESSAGE_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: messageId
            },
            P_BANK_REF: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: bankReference
            }
        };

        const connection = await getConnection();
        try {
            await connection.execute(
                `BEGIN ${this.packageName}.set_manual_status_1(:P_ID, :P_REASON, :P_NEW_STATUS, :P_MESSAGE_ID, :P_BANK_REF); END;`,
                binds
            );

            return {
                success: true,
                documentId: documentId,
                newStatus: newStatus,
                bankReference: bankReference
            };
        } finally {
            await connection.close();
        }
    }

    /**
     * Get signature owner information
     * @param {string} certId - Certificate ID
     * @param {Date|string} signDate - Signature date
     * @returns {Promise<Object>} User name and legal ID
     */
    async getSignOwner(certId, signDate) {
        const binds = {
            P_CERT_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: certId
            },
            P_SIGN_DATE: {
                type: oracledb.DATE,
                dir: oracledb.BIND_IN,
                val: new Date(signDate)
            },
            P_USER_NAME: {
                type: oracledb.STRING,
                dir: oracledb.BIND_OUT,
                maxSize: 210
            },
            P_LEGAL_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_OUT,
                maxSize: 35
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN ${this.packageName}.signOwner(:P_CERT_ID, :P_SIGN_DATE, :P_USER_NAME, :P_LEGAL_ID); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            return {
                userName: result.outBinds.P_USER_NAME,
                legalId: result.outBinds.P_LEGAL_ID,
                certificateId: certId,
                signatureDate: signDate
            };
        } finally {
            await connection.close();
        }
    }

    /**
     * Get document addresses
     * @param {string} documentId - Document ID
     * @returns {Promise<Array>} Array of addresses
     */
    async getAddresses(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('get_addr', binds);
    }

    /**
     * Get document extensions
     * @param {string} documentId - Document ID
     * @returns {Promise<Array>} Array of extensions
     */
    async getExtensions(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('get_extensions', binds);
    }

    /**
     * Get Internet Banking signatures for a document
     * @param {string} documentId - Document ID
     * @returns {Promise<Array>} Array of signatures
     */
    async getIBSignatures(documentId) {
        const binds = {
            P_DOC_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        return await this.executeProcedure('get_ib_signatures', binds);
    }

    /**
     * Enable manual processing for a document
     * @param {string} documentId - Document ID
     * @returns {Promise<Object>} Success indicator
     */
    async setManualProcessing(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_RESULT: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            }
        };

        const result = await this.executeQuery(
            `BEGIN :P_RESULT := ${this.packageName}.set_ManualProcessing(:P_ID); END;`,
            binds
        );

        return {
            success: result.outBinds.P_RESULT === 0,
            documentId: documentId,
            manualProcessingEnabled: true
        };
    }

    /**
     * Get change officer ID for a document
     * @param {string} documentId - Document ID
     * @returns {Promise<Object>} Change officer ID
     */
    async getChangeOfficerId(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: documentId
            },
            P_RESULT: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            }
        };

        const result = await this.executeQuery(
            `BEGIN :P_RESULT := ${this.packageName}.getChangeOfficerId(:P_ID); END;`,
            binds
        );

        return {
            documentId: documentId,
            changeOfficerId: result.outBinds.P_RESULT
        };
    }

    /**
     * Get basic document information by ID
     * @param {number} documentId - Document ID
     * @returns {Promise<Object>} Document basic info
     */
    async getById(documentId) {
        const binds = {
            P_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: parseInt(documentId)
            },
            P_STATUS: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            },
            P_OFFICER_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            },
            P_ITC: {
                type: oracledb.STRING,
                dir: oracledb.BIND_OUT,
                maxSize: 4000
            },
            P_RESULT: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_RESULT := ${this.packageName}.get_by_id(:P_ID, :P_STATUS, :P_OFFICER_ID, :P_ITC); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            return {
                id: documentId,
                status: result.outBinds.P_STATUS,
                officerId: result.outBinds.P_OFFICER_ID,
                infoToCustomer: result.outBinds.P_ITC,
                found: result.outBinds.P_RESULT === 0
            };
        } finally {
            await connection.close();
        }
    }
}

module.exports = DocumentsService;