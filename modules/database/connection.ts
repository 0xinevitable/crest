import sqlite3 from 'sqlite3';
import { Client } from 'pg';
import fs from 'fs';
import path from 'path';
import { ProcessedFundingRate, LogProcessingResult } from '../data-processor';

export interface DatabaseConfig {
  type: 'sqlite' | 'postgres';
  sqlite?: {
    filename: string;
  };
  postgres?: {
    host: string;
    port: number;
    database: string;
    username: string;
    password: string;
  };
}

export class DatabaseManager {
  private config: DatabaseConfig;
  private sqliteDb?: sqlite3.Database;
  private pgClient?: Client;

  constructor(config: DatabaseConfig) {
    this.config = config;
  }

  async connect(): Promise<void> {
    if (this.config.type === 'sqlite') {
      await this.connectSQLite();
    } else if (this.config.type === 'postgres') {
      await this.connectPostgres();
    }
    
    await this.initializeSchema();
  }

  private async connectSQLite(): Promise<void> {
    return new Promise((resolve, reject) => {
      const dbPath = this.config.sqlite?.filename || 'funding_rates.db';
      this.sqliteDb = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          reject(new Error(`Failed to connect to SQLite database: ${err.message}`));
        } else {
          console.log('Connected to SQLite database');
          resolve();
        }
      });
    });
  }

  private async connectPostgres(): Promise<void> {
    if (!this.config.postgres) {
      throw new Error('PostgreSQL configuration not provided');
    }

    this.pgClient = new Client({
      host: this.config.postgres.host,
      port: this.config.postgres.port,
      database: this.config.postgres.database,
      user: this.config.postgres.username,
      password: this.config.postgres.password,
    });

    await this.pgClient.connect();
    console.log('Connected to PostgreSQL database');
  }

  private async initializeSchema(): Promise<void> {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    if (this.config.type === 'sqlite' && this.sqliteDb) {
      await this.executeSQLite(schema);
    } else if (this.config.type === 'postgres' && this.pgClient) {
      await this.pgClient.query(schema);
    }
  }

  private async executeSQLite(sql: string, params: any[] = []): Promise<any> {
    return new Promise((resolve, reject) => {
      if (!this.sqliteDb) {
        reject(new Error('SQLite database not connected'));
        return;
      }

      this.sqliteDb.run(sql, params, function(err) {
        if (err) {
          reject(err);
        } else {
          resolve({ lastID: this.lastID, changes: this.changes });
        }
      });
    });
  }

  async insertFundingRates(records: ProcessedFundingRate[]): Promise<void> {
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
    } else if (this.config.type === 'postgres' && this.pgClient) {
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

  async recordProcessingHistory(logFile: string, result: LogProcessingResult): Promise<void> {
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
    } else if (this.config.type === 'postgres' && this.pgClient) {
      const pgSql = sql.replace(/\?/g, ($, index) => `$${index + 1}`);
      await this.pgClient.query(pgSql, params);
    }
  }

  async isFileProcessed(logFile: string): Promise<boolean> {
    const sql = 'SELECT 1 FROM log_processing_history WHERE log_file = ? LIMIT 1';

    if (this.config.type === 'sqlite' && this.sqliteDb) {
      return new Promise((resolve, reject) => {
        this.sqliteDb!.get(sql, [logFile], (err, row) => {
          if (err) {
            reject(err);
          } else {
            resolve(!!row);
          }
        });
      });
    } else if (this.config.type === 'postgres' && this.pgClient) {
      const pgSql = sql.replace('?', '$1');
      const result = await this.pgClient.query(pgSql, [logFile]);
      return result.rows.length > 0;
    }

    return false;
  }

  async close(): Promise<void> {
    if (this.sqliteDb) {
      await new Promise<void>((resolve, reject) => {
        this.sqliteDb!.close((err) => {
          if (err) {
            reject(err);
          } else {
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