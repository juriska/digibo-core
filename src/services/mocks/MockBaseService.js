// Mock base service for local development without database

class MockBaseService {
    constructor(packageName) {
        this.packageName = packageName;
        console.log(`[MOCK MODE] Initialized mock service for package: ${packageName}`);
    }

    async executeProcedure(procedureName, binds) {
        console.log(`[MOCK MODE] Executing mock procedure: ${this.packageName}.${procedureName}`);
        console.log('[MOCK MODE] Bind parameters:', binds);

        // Return empty array by default - subclasses should override
        return [];
    }

    async executeQuery(sql, binds = {}) {
        console.log(`[MOCK MODE] Executing mock query: ${sql}`);
        console.log('[MOCK MODE] Bind parameters:', binds);

        // Return empty array by default - subclasses should override
        return [];
    }
}

module.exports = MockBaseService;