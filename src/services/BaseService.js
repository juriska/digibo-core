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

    /**
     * Execute a stored procedure that returns a cursor
     * @param {string} procedureName - Name of the procedure/function
     * @param {Object} inputBinds - Input bind parameters (without P_CURSOR)
     * @returns {Promise<Array>} Rows from the cursor
     */
    async executeCursorProcedure(procedureName, inputBinds = {}) {
        let connection;

        try {
            connection = await getConnection();

            // Add cursor output parameter
            const binds = {
                ...inputBinds,
                P_CURSOR: {
                    type: oracledb.CURSOR,
                    dir: oracledb.BIND_OUT
                }
            };

            // Build parameter list for PL/SQL call (exclude P_CURSOR from params)
            const inputParamNames = Object.keys(inputBinds);
            const paramList = inputParamNames.map(key => `:${key}`).join(', ');

            // Construct PL/SQL call
            const plsql = paramList
                ? `BEGIN :P_CURSOR := ${this.packageName}.${procedureName}(${paramList}); END;`
                : `BEGIN :P_CURSOR := ${this.packageName}.${procedureName}(); END;`;

            console.log(`[DB] Executing cursor procedure: ${plsql}`);

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

    /**
     * Execute a stored function that returns a scalar value
     * @param {string} functionName - Name of the function
     * @param {Object} inputBinds - Input bind parameters (without return parameter)
     * @param {Object} returnType - Oracle type for return value (e.g., oracledb.NUMBER, oracledb.STRING)
     * @returns {Promise<any>} Return value from the function
     */
    async executeScalarFunction(functionName, inputBinds = {}, returnType = oracledb.NUMBER) {
        let connection;

        try {
            connection = await getConnection();

            // Add return parameter
            const binds = {
                ...inputBinds,
                P_RESULT: {
                    type: returnType,
                    dir: oracledb.BIND_OUT
                }
            };

            // Build parameter list for PL/SQL call
            const inputParamNames = Object.keys(inputBinds);
            const paramList = inputParamNames.map(key => `:${key}`).join(', ');

            // Construct PL/SQL call
            const plsql = paramList
                ? `BEGIN :P_RESULT := ${this.packageName}.${functionName}(${paramList}); END;`
                : `BEGIN :P_RESULT := ${this.packageName}.${functionName}(); END;`;

            console.log(`[DB] Executing scalar function: ${plsql}`);

            const result = await connection.execute(plsql, binds);

            console.log(`[DB] Success: ${this.packageName}.${functionName} returned ${result.outBinds.P_RESULT}`);
            return result.outBinds.P_RESULT;
        } catch (err) {
            console.error(`[DB ERROR] Failed to execute ${this.packageName}.${functionName}:`);
            console.error(`[DB ERROR] Message: ${err.message}`);
            console.error(`[DB ERROR] Code: ${err.code || 'N/A'}`);

            const error = new Error(`Database error: ${err.message}`);
            error.originalError = err;
            error.package = this.packageName;
            error.procedure = functionName;
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

    /**
     * Execute a stored procedure (no return value, but may have OUT parameters)
     * @param {string} procedureName - Name of the procedure
     * @param {Object} binds - All bind parameters (IN, OUT, INOUT)
     * @param {boolean} commit - Whether to commit the transaction (default: true)
     * @returns {Promise<Object>} Output binds
     */
    async executeVoidProcedure(procedureName, binds = {}, commit = true) {
        let connection;

        try {
            connection = await getConnection();

            // Build parameter list for PL/SQL call
            const paramNames = Object.keys(binds);
            const paramList = paramNames.map(key => `:${key}`).join(', ');

            // Construct PL/SQL call
            const plsql = paramList
                ? `BEGIN ${this.packageName}.${procedureName}(${paramList}); END;`
                : `BEGIN ${this.packageName}.${procedureName}(); END;`;

            console.log(`[DB] Executing void procedure: ${plsql}`);

            const result = await connection.execute(plsql, binds);

            if (commit) {
                await connection.commit();
            }

            console.log(`[DB] Success: ${this.packageName}.${procedureName} executed`);
            return result.outBinds || {};
        } catch (err) {
            console.error(`[DB ERROR] Failed to execute ${this.packageName}.${procedureName}:`);
            console.error(`[DB ERROR] Message: ${err.message}`);
            console.error(`[DB ERROR] Code: ${err.code || 'N/A'}`);

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

}

module.exports = BaseService; 