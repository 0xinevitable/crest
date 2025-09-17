import { RawLogData, LogProcessingResult } from '../types/funding-rate';
export declare class LogParser {
    static parseLogFile(rawData: RawLogData, logFileName: string): LogProcessingResult;
    private static processFundingData;
    static extractTimestampFromFileName(fileName: string): Date | null;
}
//# sourceMappingURL=log-parser.d.ts.map