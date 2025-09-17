import { DatabaseConfig } from '../../modules/database';
declare class LogProcessor {
    private dbManager;
    private logsDirectory;
    constructor(dbConfig: DatabaseConfig, logsDirectory?: string);
    initialize(): Promise<void>;
    processAllLogs(): Promise<void>;
    private processLogFile;
    private extractProcessedRecords;
    shutdown(): Promise<void>;
}
export { LogProcessor };
//# sourceMappingURL=index.d.ts.map