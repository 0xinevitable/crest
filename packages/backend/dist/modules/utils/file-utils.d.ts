import fs from 'fs';
import { RawLogData } from '../data-processor/types/funding-rate';
export declare class FileUtils {
    ensureDirectory(dirPath: string): Promise<void>;
    writeJson(filePath: string, data: any): Promise<void>;
    static readJsonFile<T = any>(filePath: string): Promise<T>;
    static getLogFiles(logsDirectory: string): Promise<string[]>;
    static fileExists(filePath: string): Promise<boolean>;
    static ensureDirectoryExists(dirPath: string): Promise<void>;
    static getFileName(filePath: string): string;
    static getFileStats(filePath: string): Promise<fs.Stats>;
    static loadLogData(filePath: string): Promise<RawLogData>;
    static formatFileSize(bytes: number): string;
}
export declare const fileUtils: FileUtils;
//# sourceMappingURL=file-utils.d.ts.map