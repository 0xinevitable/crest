"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LogProcessor = void 0;
const path_1 = __importDefault(require("path"));
const data_processor_1 = require("../../modules/data-processor");
const database_1 = require("../../modules/database");
const utils_1 = require("../../modules/utils");
class LogProcessor {
    constructor(dbConfig, logsDirectory = 'logs') {
        this.dbManager = new database_1.DatabaseManager(dbConfig);
        this.logsDirectory = path_1.default.resolve(logsDirectory);
    }
    async initialize() {
        console.log('Initializing log processor...');
        await this.dbManager.connect();
        console.log('Database connected successfully');
    }
    async processAllLogs() {
        try {
            console.log(`Scanning for log files in: ${this.logsDirectory}`);
            const logFiles = await utils_1.FileUtils.getLogFiles(this.logsDirectory);
            if (logFiles.length === 0) {
                console.log('No log files found');
                return;
            }
            console.log(`Found ${logFiles.length} log file(s)`);
            for (const logFile of logFiles) {
                await this.processLogFile(logFile);
            }
            console.log('All log files processed successfully');
        }
        catch (error) {
            console.error('Error processing logs:', error.message);
            throw error;
        }
    }
    async processLogFile(logFilePath) {
        const fileName = utils_1.FileUtils.getFileName(logFilePath);
        console.log(`\nProcessing: ${fileName}`);
        try {
            const alreadyProcessed = await this.dbManager.isFileProcessed(fileName);
            if (alreadyProcessed) {
                console.log(`  ⏭️  Skipped (already processed)`);
                return;
            }
            const fileStats = await utils_1.FileUtils.getFileStats(logFilePath);
            console.log(`  📁 Size: ${utils_1.FileUtils.formatFileSize(fileStats.size)}`);
            const logData = await utils_1.FileUtils.loadLogData(logFilePath);
            console.log(`  📊 Loaded raw data`);
            const result = data_processor_1.LogParser.parseLogFile(logData, fileName);
            console.log(`  ✅ Parsed: ${result.successfulRecords}/${result.totalRecords} records`);
            if (result.errors.length > 0) {
                console.log(`  ⚠️  Errors: ${result.errors.length}`);
                result.errors.forEach(error => console.log(`     ${error}`));
            }
            if (result.successfulRecords > 0) {
                const processedRecords = this.extractProcessedRecords(logData, fileName);
                await this.dbManager.insertFundingRates(processedRecords);
                console.log(`  💾 Saved to database`);
            }
            await this.dbManager.recordProcessingHistory(fileName, result);
            console.log(`  📝 Recorded processing history`);
        }
        catch (error) {
            console.error(`  ❌ Failed to process ${fileName}:`, error.message);
            await this.dbManager.recordProcessingHistory(fileName, {
                totalRecords: 0,
                successfulRecords: 0,
                errors: [error.message]
            });
        }
    }
    extractProcessedRecords(logData, fileName) {
        const result = data_processor_1.LogParser.parseLogFile(logData, fileName);
        const processedRecords = [];
        for (const [symbol, exchanges] of logData) {
            for (const [exchangeName, fundingData] of exchanges) {
                if (fundingData === null)
                    continue;
                try {
                    const fundingRate = parseFloat(fundingData.fundingRate);
                    if (isNaN(fundingRate))
                        continue;
                    const nextFundingTime = new Date(fundingData.nextFundingTime);
                    if (isNaN(nextFundingTime.getTime()))
                        continue;
                    processedRecords.push({
                        symbol,
                        exchange: exchangeName,
                        fundingRate,
                        nextFundingTime,
                        fundingIntervalHours: fundingData.fundingIntervalHours || null,
                        processedAt: new Date(),
                        logFile: fileName
                    });
                }
                catch (error) {
                }
            }
        }
        return processedRecords;
    }
    async shutdown() {
        console.log('\nShutting down log processor...');
        await this.dbManager.close();
        console.log('Shutdown complete');
    }
}
exports.LogProcessor = LogProcessor;
async function main() {
    const dbConfig = {
        type: 'sqlite',
        sqlite: {
            filename: 'funding_rates.db'
        }
    };
    const processor = new LogProcessor(dbConfig);
    try {
        await processor.initialize();
        await processor.processAllLogs();
    }
    catch (error) {
        console.error('Fatal error:', error);
        process.exit(1);
    }
    finally {
        await processor.shutdown();
    }
}
if (require.main === module) {
    main().catch(console.error);
}
//# sourceMappingURL=index.js.map