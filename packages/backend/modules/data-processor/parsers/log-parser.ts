import {
  ExchangeFundingData,
  LogProcessingResult,
  ProcessedFundingRate,
  RawLogData,
} from '../types/funding-rate';

export class LogParser {
  static parseLogFile(
    rawData: RawLogData,
    logFileName: string,
  ): LogProcessingResult {
    const processedRecords: ProcessedFundingRate[] = [];
    const errors: string[] = [];
    let totalRecords = 0;

    try {
      for (const [symbol, exchanges] of rawData) {
        for (const [exchangeName, fundingData] of exchanges) {
          totalRecords++;

          try {
            if (fundingData === null) {
              continue;
            }

            const processedRecord = this.processFundingData(
              symbol,
              exchangeName,
              fundingData,
              logFileName,
            );

            if (processedRecord) {
              processedRecords.push(processedRecord);
            }
          } catch (error) {
            errors.push(
              `Error processing ${symbol}-${exchangeName}: ${error.message}`,
            );
          }
        }
      }
    } catch (error) {
      errors.push(`Error parsing log file ${logFileName}: ${error.message}`);
    }

    return {
      totalRecords,
      successfulRecords: processedRecords.length,
      errors,
    };
  }

  private static processFundingData(
    symbol: string,
    exchange: string,
    data: ExchangeFundingData,
    logFileName: string,
  ): ProcessedFundingRate | null {
    const fundingRate = parseFloat(data.fundingRate);

    if (isNaN(fundingRate)) {
      throw new Error(`Invalid funding rate: ${data.fundingRate}`);
    }

    const nextFundingTime = new Date(data.nextFundingTime);

    if (isNaN(nextFundingTime.getTime())) {
      throw new Error(`Invalid next funding time: ${data.nextFundingTime}`);
    }

    return {
      symbol,
      exchange,
      fundingRate,
      nextFundingTime,
      fundingIntervalHours: data.fundingIntervalHours || null,
      processedAt: new Date(),
      logFile: logFileName,
    };
  }

  static extractTimestampFromFileName(fileName: string): Date | null {
    const match = fileName.match(/(\d{12})/);
    if (!match) return null;

    const timestamp = match[1];
    const year = parseInt(timestamp.substring(0, 4));
    const month = parseInt(timestamp.substring(4, 6)) - 1;
    const day = parseInt(timestamp.substring(6, 8));
    const hour = parseInt(timestamp.substring(8, 10));
    const minute = parseInt(timestamp.substring(10, 12));

    return new Date(year, month, day, hour, minute);
  }
}
