"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DatabaseManager = void 0;
const sqlite3_1 = __importDefault(require("sqlite3"));
const pg_1 = require("pg");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
class DatabaseManager {
    constructor(config) {
        this.config = config;
    }
    async connect() {
        if (this.config.type === 'sqlite') {
            await this.connectSQLite();
        }
        else if (this.config.type === 'postgres') {
            await this.connectPostgres();
        }
        await this.initializeSchema();
    }
    async connectSQLite() {
        return new Promise((resolve, reject) => {
            const dbPath = this.config.sqlite?.filename || 'funding_rates.db';
            this.sqliteDb = new sqlite3_1.default.Database(dbPath, (err) => {
                if (err) {
                    reject(new Error(`Failed to connect to SQLite database: ${err.message}`));
                }
                else {
                    console.log('Connected to SQLite database');
                    resolve();
                }
            });
        });
    }
    async connectPostgres() {
        if (!this.config.postgres) {
            throw new Error('PostgreSQL configuration not provided');
        }
        this.pgClient = new pg_1.Client({
            host: this.config.postgres.host,
            port: this.config.postgres.port,
            database: this.config.postgres.database,
            user: this.config.postgres.username,
            password: this.config.postgres.password,
        });
        await this.pgClient.connect();
        console.log('Connected to PostgreSQL database');
    }
    async initializeSchema() {
        const schemaPath = path_1.default.join(__dirname, 'schema.sql');
        const schema = fs_1.default.readFileSync(schemaPath, 'utf8');
        if (this.config.type === 'sqlite' && this.sqliteDb) {
            await this.executeSQLite(schema);
        }
        else if (this.config.type === 'postgres' && this.pgClient) {
            await this.pgClient.query(schema);
        }
    }
    async executeSQLite(sql, params = []) {
        return new Promise((resolve, reject) => {
            if (!this.sqliteDb) {
                reject(new Error('SQLite database not connected'));
                return;
            }
            this.sqliteDb.run(sql, params, function (err) {
                if (err) {
                    reject(err);
                }
                else {
                    resolve({ lastID: this.lastID, changes: this.changes });
                }
            });
        });
    }
    async insertFundingRates(records) {
        const sql = `
      INSERT OR IGNORE INTO funding_rates 
      (symbol, exchange, funding_rate, next_funding_time, funding_interval_hours, processed_at, log_file)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
        if (this.config.type === 'sqlite' && this.sqliteDb) {
            for (const record of records) {
                await this.executeSQLite(sql, [
                    record.symbol,
                    record.exchange,
                    record.fundingRate,
                    record.nextFundingTime.toISOString(),
                    record.fundingIntervalHours,
                    record.processedAt.toISOString(),
                    record.logFile
                ]);
            }
        }
        else if (this.config.type === 'postgres' && this.pgClient) {
            const pgSql = sql.replace(/\?/g, ($, index) => `$${index + 1}`);
            for (const record of records) {
                await this.pgClient.query(pgSql, [
                    record.symbol,
                    record.exchange,
                    record.fundingRate,
                    record.nextFundingTime,
                    record.fundingIntervalHours,
                    record.processedAt,
                    record.logFile
                ]);
            }
        }
    }
    async recordProcessingHistory(logFile, result) {
        const sql = `
      INSERT OR REPLACE INTO log_processing_history 
      (log_file, total_records, successful_records, error_count, errors)
      VALUES (?, ?, ?, ?, ?)
    `;
        const params = [
            logFile,
            result.totalRecords,
            result.successfulRecords,
            result.errors.length,
            JSON.stringify(result.errors)
        ];
        if (this.config.type === 'sqlite') {
            await this.executeSQLite(sql, params);
        }
        else if (this.config.type === 'postgres' && this.pgClient) {
            const pgSql = sql.replace(/\?/g, ($, index) => `$${index + 1}`);
            await this.pgClient.query(pgSql, params);
        }
    }
    async isFileProcessed(logFile) {
        const sql = 'SELECT 1 FROM log_processing_history WHERE log_file = ? LIMIT 1';
        if (this.config.type === 'sqlite' && this.sqliteDb) {
            return new Promise((resolve, reject) => {
                this.sqliteDb.get(sql, [logFile], (err, row) => {
                    if (err) {
                        reject(err);
                    }
                    else {
                        resolve(!!row);
                    }
                });
            });
        }
        else if (this.config.type === 'postgres' && this.pgClient) {
            const pgSql = sql.replace('?', '$1');
            const result = await this.pgClient.query(pgSql, [logFile]);
            return result.rows.length > 0;
        }
        return false;
    }
    async close() {
        if (this.sqliteDb) {
            await new Promise((resolve, reject) => {
                this.sqliteDb.close((err) => {
                    if (err) {
                        reject(err);
                    }
                    else {
                        console.log('SQLite database connection closed');
                        resolve();
                    }
                });
            });
        }
        if (this.pgClient) {
            await this.pgClient.end();
            console.log('PostgreSQL database connection closed');
        }
    }
}
exports.DatabaseManager = DatabaseManager;
//# sourceMappingURL=connection.js.map