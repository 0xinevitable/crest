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
export declare class DatabaseManager {
    private config;
    private sqliteDb?;
    private pgClient?;
    constructor(config: DatabaseConfig);
    connect(): Promise<void>;
    private connectSQLite;
    private connectPostgres;
    private initializeSchema;
    private executeSQLite;
    insertFundingRates(records: ProcessedFundingRate[]): Promise<void>;
    recordProcessingHistory(logFile: string, result: LogProcessingResult): Promise<void>;
    isFileProcessed(logFile: string): Promise<boolean>;
    close(): Promise<void>;
}
//# sourceMappingURL=connection.d.ts.map