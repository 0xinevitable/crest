"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logFetcher = exports.LogFetcher = void 0;
const http_client_1 = require("../utils/http-client");
const file_utils_1 = require("../utils/file-utils");
class LogFetcher {
    constructor(config = {}) {
        this.config = {
            hyperliquidApiUrl: 'https://api-ui.hyperliquid.xyz/info',
            retryAttempts: 3,
            retryDelayMs: 1000,
            requestTimeoutMs: 30000,
            ...config
        };
    }
    /**
     * Fetch funding rates from Hyperliquid API and save to filesystem
     */
    async fetchAndSave(baseDir = './logs') {
        const timestamp = new Date();
        const filename = this.generateFilename(timestamp);
        const filepath = `${baseDir}/${filename}`;
        try {
            console.log('Fetching funding rates from Hyperliquid API...');
            const data = await this.fetchWithRetry();
            console.log(`Received ${data.length} symbols from API`);
            // Ensure directory exists
            await file_utils_1.fileUtils.ensureDirectory(baseDir);
            // Save to file
            await file_utils_1.fileUtils.writeJson(filepath, data);
            console.log(`Funding rates saved to ${filepath}`);
            return {
                success: true,
                filename,
                filepath,
                recordCount: data.length,
                timestamp
            };
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('Failed to fetch and save funding rates:', errorMessage);
            return {
                success: false,
                error: errorMessage,
                timestamp
            };
        }
    }
    /**
     * Fetch funding rates from API with retry logic
     */
    async fetchWithRetry() {
        let lastError = null;
        for (let attempt = 1; attempt <= this.config.retryAttempts; attempt++) {
            try {
                console.log(`Attempt ${attempt}/${this.config.retryAttempts}: Fetching from ${this.config.hyperliquidApiUrl}`);
                const response = await http_client_1.httpClient.post(this.config.hyperliquidApiUrl, { type: 'predictedFundings' }, {
                    'Content-Type': 'application/json'
                });
                if (!Array.isArray(response.data)) {
                    throw new Error('Invalid response format: expected array');
                }
                console.log(`Successfully fetched data on attempt ${attempt}`);
                return response.data;
            }
            catch (error) {
                lastError = error instanceof Error ? error : new Error('Unknown error');
                console.warn(`Attempt ${attempt} failed:`, lastError.message);
                if (attempt < this.config.retryAttempts) {
                    console.log(`Waiting ${this.config.retryDelayMs}ms before retry...`);
                    await this.delay(this.config.retryDelayMs);
                }
            }
        }
        throw new Error(`Failed to fetch after ${this.config.retryAttempts} attempts. Last error: ${lastError?.message}`);
    }
    /**
     * Generate filename with timestamp
     */
    generateFilename(timestamp) {
        const year = timestamp.getFullYear();
        const month = String(timestamp.getMonth() + 1).padStart(2, '0');
        const day = String(timestamp.getDate()).padStart(2, '0');
        const hour = String(timestamp.getHours()).padStart(2, '0');
        const minute = String(timestamp.getMinutes()).padStart(2, '0');
        return `${year}${month}${day}${hour}${minute}-funding-rates.json`;
    }
    /**
     * Simple delay utility
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    /**
     * Test API connectivity
     */
    async testConnection() {
        try {
            const response = await http_client_1.httpClient.post(this.config.hyperliquidApiUrl, { type: 'predictedFundings' });
            return Array.isArray(response.data) && response.data.length > 0;
        }
        catch (error) {
            console.error('Connection test failed:', error instanceof Error ? error.message : 'Unknown error');
            return false;
        }
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
    /**
     * Update configuration
     */
    updateConfig(newConfig) {
        this.config = { ...this.config, ...newConfig };
    }
}
exports.LogFetcher = LogFetcher;
exports.logFetcher = new LogFetcher();
//# sourceMappingURL=log-fetcher.js.map