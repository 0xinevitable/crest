"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.fileUtils = exports.FileUtils = void 0;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
class FileUtils {
    async ensureDirectory(dirPath) {
        try {
            await fs_1.default.promises.mkdir(dirPath, { recursive: true });
        }
        catch (error) {
            throw new Error(`Failed to create directory ${dirPath}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    async writeJson(filePath, data) {
        try {
            const jsonString = JSON.stringify(data, null, 2);
            await fs_1.default.promises.writeFile(filePath, jsonString, 'utf8');
        }
        catch (error) {
            throw new Error(`Failed to write JSON to ${filePath}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    static async readJsonFile(filePath) {
        try {
            const fileContent = await fs_1.default.promises.readFile(filePath, 'utf8');
            return JSON.parse(fileContent);
        }
        catch (error) {
            throw new Error(`Failed to read or parse JSON file ${filePath}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    static async getLogFiles(logsDirectory) {
        try {
            const files = await fs_1.default.promises.readdir(logsDirectory);
            return files
                .filter(file => file.endsWith('.json'))
                .map(file => path_1.default.join(logsDirectory, file))
                .sort();
        }
        catch (error) {
            throw new Error(`Failed to read logs directory ${logsDirectory}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    static async fileExists(filePath) {
        try {
            await fs_1.default.promises.access(filePath, fs_1.default.constants.F_OK);
            return true;
        }
        catch {
            return false;
        }
    }
    static async ensureDirectoryExists(dirPath) {
        try {
            await fs_1.default.promises.mkdir(dirPath, { recursive: true });
        }
        catch (error) {
            throw new Error(`Failed to create directory ${dirPath}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    static getFileName(filePath) {
        return path_1.default.basename(filePath);
    }
    static async getFileStats(filePath) {
        try {
            return await fs_1.default.promises.stat(filePath);
        }
        catch (error) {
            throw new Error(`Failed to get file stats for ${filePath}: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }
    static async loadLogData(filePath) {
        const data = await this.readJsonFile(filePath);
        if (!Array.isArray(data)) {
            throw new Error(`Invalid log data format in ${filePath}: expected array`);
        }
        return data;
    }
    static formatFileSize(bytes) {
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        if (bytes === 0)
            return '0 Bytes';
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
    }
}
exports.FileUtils = FileUtils;
exports.fileUtils = new FileUtils();
//# sourceMappingURL=file-utils.js.map