import path from 'path';
import { LogParser, ProcessedFundingRate } from '../../modules/data-processor';
import { DatabaseManager, DatabaseConfig } from '../../modules/database';
import { FileUtils } from '../../modules/utils';

class LogProcessor {
  private dbManager: DatabaseManager;
  private logsDirectory: string;

  constructor(dbConfig: DatabaseConfig, logsDirectory: string = 'logs') {
    this.dbManager = new DatabaseManager(dbConfig);
    this.logsDirectory = path.resolve(logsDirectory);
  }

  async initialize(): Promise<void> {
    console.log('Initializing log processor...');
    await this.dbManager.connect();
    console.log('Database connected successfully');
  }

  async processAllLogs(): Promise<void> {
    try {
      console.log(`Scanning for log files in: ${this.logsDirectory}`);
      const logFiles = await FileUtils.getLogFiles(this.logsDirectory);
      
      if (logFiles.length === 0) {
        console.log('No log files found');
        return;
      }

      console.log(`Found ${logFiles.length} log file(s)`);

      for (const logFile of logFiles) {
        await this.processLogFile(logFile);
      }

      console.log('All log files processed successfully');
    } catch (error) {
      console.error('Error processing logs:', error.message);
      throw error;
    }
  }

  private async processLogFile(logFilePath: string): Promise<void> {
    const fileName = FileUtils.getFileName(logFilePath);
    
    console.log(`\nProcessing: ${fileName}`);

    try {
      const alreadyProcessed = await this.dbManager.isFileProcessed(fileName);
      if (alreadyProcessed) {
        console.log(`  ⏭️  Skipped (already processed)`);
        return;
      }

      const fileStats = await FileUtils.getFileStats(logFilePath);
      console.log(`  📁 Size: ${FileUtils.formatFileSize(fileStats.size)}`);

      const logData = await FileUtils.loadLogData(logFilePath);
      console.log(`  📊 Loaded raw data`);

      const result = LogParser.parseLogFile(logData, fileName);
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

    } catch (error) {
      console.error(`  ❌ Failed to process ${fileName}:`, error.message);
      
      await this.dbManager.recordProcessingHistory(fileName, {
        totalRecords: 0,
        successfulRecords: 0,
        errors: [error.message]
      });
    }
  }

  private extractProcessedRecords(logData: any, fileName: string): ProcessedFundingRate[] {
    const result = LogParser.parseLogFile(logData, fileName);
    const processedRecords: ProcessedFundingRate[] = [];

    for (const [symbol, exchanges] of logData) {
      for (const [exchangeName, fundingData] of exchanges) {
        if (fundingData === null) continue;

        try {
          const fundingRate = parseFloat(fundingData.fundingRate);
          if (isNaN(fundingRate)) continue;

          const nextFundingTime = new Date(fundingData.nextFundingTime);
          if (isNaN(nextFundingTime.getTime())) continue;

          processedRecords.push({
            symbol,
            exchange: exchangeName,
            fundingRate,
            nextFundingTime,
            fundingIntervalHours: fundingData.fundingIntervalHours || null,
            processedAt: new Date(),
            logFile: fileName
          });
        } catch (error) {
        }
      }
    }

    return processedRecords;
  }

  async shutdown(): Promise<void> {
    console.log('\nShutting down log processor...');
    await this.dbManager.close();
    console.log('Shutdown complete');
  }
}

async function main() {
  const dbConfig: DatabaseConfig = {
    type: 'sqlite',
    sqlite: {
      filename: 'funding_rates.db'
    }
  };

  const processor = new LogProcessor(dbConfig);

  try {
    await processor.initialize();
    await processor.processAllLogs();
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  } finally {
    await processor.shutdown();
  }
}

if (require.main === module) {
  main().catch(console.error);
}

export { LogProcessor };