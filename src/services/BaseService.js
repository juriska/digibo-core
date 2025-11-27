const oracledb = require('oracledb');

const {getConnection} = require('../config/database');

class BaseService {
    constructor(packageName) {
        this.packageName = packageName;
    }

    async executeProcedure(procedureName, binds) {
        let connection;

        try {
            connection = await getConnection();

            // Create bind parameter string
            const bindParams = Object.keys(binds)
                .filter(key => key !== 'P_CURSOR')
                .map(key => `:${key}`)
                .join(', ');

            const plsql = `BEGIN ${this.packageName}.${procedureName}(${bindParams}, :P_CURSOR); END;`;
            console.log(`[DB] Executing: ${plsql}`);

            const result = await connection.execute(
                plsql,
                binds,
                {outFormat: oracledb.OUT_FORMAT_OBJECT}
            );

            const resultSet = result.outBinds.P_CURSOR;
            const rows = await resultSet.getRows();
            await resultSet.close();

            console.log(`[DB] Success: ${this.packageName}.${procedureName} returned ${rows.length} rows`);
            return rows;
        } catch (err) {
            console.error(`[DB ERROR] Failed to execute ${this.packageName}.${procedureName}:`);
            console.error(`[DB ERROR] Message: ${err.message}`);
            console.error(`[DB ERROR] Code: ${err.code || 'N/A'}`);

            // Create a more user-friendly error
            const error = new Error(`Database error: ${err.message}`);
            error.originalError = err;
            error.package = this.packageName;
            error.procedure = procedureName;
            error.code = err.code;

            throw error;
        } finally {
            if (connection) {
                try {
                    await connection.close();
                } catch (closeErr) {
                    console.error('[DB ERROR] Error closing connection:', closeErr);
                }
            }
        }
    }

    async executeQuery(sql, binds = {}) {
        let connection;
        try {
            connection = await getConnection();

            const result = await connection.execute(
                sql,
                binds,
                {outFormat: oracledb.OUT_FORMAT_OBJECT}
            );

            return result.rows;
        } catch (err) {
            console.error(`Error executing query: ${sql}`, err);
            throw err;
        } finally {
            if (connection) {
                try {
                    await connection.close();
                } catch (closeErr) {
                    console.error('Error closing connection:', closeErr);
                }
            }
        }
    }

}

module.exports = BaseService; 