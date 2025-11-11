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


            const result = await connection.execute(
                `BEGIN ${this.packageName}.${procedureName}(${bindParams}, :P_CURSOR); END;`,
                binds,
                {outFormat: oracledb.OUT_FORMAT_OBJECT}
            );

            const resultSet = result.outBinds.P_CURSOR;
            const rows = await resultSet.getRows();
            await resultSet.close();
            return rows;
        } catch (err) {
            console.error(`Error executing ${this.packageName}.${procedureName}:`, err);
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