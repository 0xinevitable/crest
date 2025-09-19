import fs from 'fs';
import path from 'path';

import { RawLogData } from '../data-processor/types/funding-rate';

export class FileUtils {
  async ensureDirectory(dirPath: string): Promise<void> {
    try {
      await fs.promises.mkdir(dirPath, { recursive: true });
    } catch (error) {
      throw new Error(
        `Failed to create directory ${dirPath}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  async writeJson(filePath: string, data: any): Promise<void> {
    try {
      const jsonString = JSON.stringify(data, null, 2);
      await fs.promises.writeFile(filePath, jsonString, 'utf8');
    } catch (error) {
      throw new Error(
        `Failed to write JSON to ${filePath}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }
  static async readJsonFile<T = any>(filePath: string): Promise<T> {
    try {
      const fileContent = await fs.promises.readFile(filePath, 'utf8');
      return JSON.parse(fileContent) as T;
    } catch (error) {
      throw new Error(
        `Failed to read or parse JSON file ${filePath}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  static async getLogFiles(logsDirectory: string): Promise<string[]> {
    try {
      const files = await fs.promises.readdir(logsDirectory);
      return files
        .filter((file) => file.endsWith('.json'))
        .map((file) => path.join(logsDirectory, file))
        .sort();
    } catch (error) {
      throw new Error(
        `Failed to read logs directory ${logsDirectory}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  static async fileExists(filePath: string): Promise<boolean> {
    try {
      await fs.promises.access(filePath, fs.constants.F_OK);
      return true;
    } catch {
      return false;
    }
  }

  static async ensureDirectoryExists(dirPath: string): Promise<void> {
    try {
      await fs.promises.mkdir(dirPath, { recursive: true });
    } catch (error) {
      throw new Error(
        `Failed to create directory ${dirPath}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  static getFileName(filePath: string): string {
    return path.basename(filePath);
  }

  static async getFileStats(filePath: string): Promise<fs.Stats> {
    try {
      return await fs.promises.stat(filePath);
    } catch (error) {
      throw new Error(
        `Failed to get file stats for ${filePath}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  static async loadLogData(filePath: string): Promise<RawLogData> {
    const data = await this.readJsonFile<RawLogData>(filePath);

    if (!Array.isArray(data)) {
      throw new Error(`Invalid log data format in ${filePath}: expected array`);
    }

    return data;
  }

  static formatFileSize(bytes: number): string {
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 Bytes';

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round((bytes / Math.pow(1024, i)) * 100) / 100 + ' ' + sizes[i];
  }
}

export const fileUtils = new FileUtils();
