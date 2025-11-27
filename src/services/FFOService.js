const oracledb = require('oracledb');
const BaseService = require('./BaseService');
const { getConnection } = require('../config/database');

/**
 * FFOService - Service for IB.BOFFO Oracle package
 * Handles Free-Form Orders and related operations
 */
class FFOService extends BaseService {
    constructor() {
        super('BOFFO');
    }

    /**
     * Get user's FFO documents using find_my function
     * Returns cursor with 19 columns matching the exact Oracle structure
     *
     * @returns {Promise<Array>} Array of FFO documents
     *
     * Structure returned:
     * - ID, CLASS_ID, STATUS_ID, ORDER_DATE, DOCUMENT_NUMBER
     * - CREATOR_CHANNEL_ID, LOGIN, FF_SUBJECT, WOC_ID, GLB_CUST_ID
     * - SECTOR, SEGMENT, ISDOCUMENTATTACHED, CATEGORY_ID, SUBCATEGORY_ID
     * - CATEGORY_NAME, SUBCATEGORY_NAME, ASSIGNEE, DOCUMENT_ATTACHED
     */
    async findMy() {
        console.log('[FFOService] Calling BOFFO.find_my()');

        const binds = {
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_CURSOR := ${this.packageName}.find_my(); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            const resultSet = result.outBinds.P_CURSOR;
            const rows = await resultSet.getRows();
            await resultSet.close();

            console.log(`[FFOService] find_my returned ${rows.length} rows`);
            return rows;
        } finally {
            await connection.close();
        }
    }

    /**
     * Get FFO document by ID
     * @param {string} documentId - Document ID
     * @returns {Promise<Object>} FFO document details
     */
    async getById(documentId) {
        console.log(`[FFOService] Getting FFO document by ID: ${documentId}`);

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

        // Note: Using find_by_id internal function (not exposed in package spec)
        // Alternative: use find_my and filter in Node.js
        const rows = await this.findMy();
        const doc = rows.find(d => d.ID == documentId);

        return doc || null;
    }

    /**
     * Get FFO categories
     * @returns {Promise<Array>} Array of categories
     */
    async getCategories() {
        console.log('[FFOService] Calling BOFFO.get_categories()');

        const binds = {
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_CURSOR := ${this.packageName}.get_categories(); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            const resultSet = result.outBinds.P_CURSOR;
            const rows = await resultSet.getRows();
            await resultSet.close();

            console.log(`[FFOService] get_categories returned ${rows.length} rows`);
            return rows;
        } finally {
            await connection.close();
        }
    }

    /**
     * Categorize FFO document
     * @param {number} docId - Document ID
     * @param {number} categoryId - Category ID
     * @param {number} subCategoryId - Subcategory ID
     * @param {number} assignee - Assignee officer ID
     * @returns {Promise<Object>} Result with success indicator
     */
    async categorize(docId, categoryId, subCategoryId, assignee) {
        console.log(`[FFOService] Categorizing document ${docId}`);

        const binds = {
            P_DOC_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: docId
            },
            P_CATEGORY_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: categoryId
            },
            P_SUBCATEGORY_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: subCategoryId
            },
            P_ASSIGNEE: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: assignee
            },
            P_RESULT: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_RESULT := ${this.packageName}.categorize(:P_DOC_ID, :P_CATEGORY_ID, :P_SUBCATEGORY_ID, :P_ASSIGNEE); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            const success = result.outBinds.P_RESULT === 0;

            return {
                success,
                documentId: docId,
                categoryId,
                subCategoryId,
                assignee,
                result: result.outBinds.P_RESULT
            };
        } finally {
            await connection.close();
        }
    }

    /**
     * Set processing status for FFO document
     * @param {string} docId - Document ID
     * @param {string} reason - Reason for status change
     * @param {number} newStatus - New status ID
     * @param {number} messageId - Message ID
     * @returns {Promise<Object>} Result with success indicator
     */
    async setProcessing(docId, reason, newStatus, messageId) {
        console.log(`[FFOService] Setting processing status for document ${docId}`);

        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: docId
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
            P_RESULT: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_OUT
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_RESULT := ${this.packageName}.set_processing(:P_ID, :P_REASON, :P_NEW_STATUS, :P_MESSAGE_ID); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            const success = result.outBinds.P_RESULT === 0;

            return {
                success,
                documentId: docId,
                newStatus,
                result: result.outBinds.P_RESULT
            };
        } finally {
            await connection.close();
        }
    }
}

module.exports = FFOService; 