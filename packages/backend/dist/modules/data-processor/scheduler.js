"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.fundingRateScheduler = exports.FundingRateScheduler = void 0;
const log_fetcher_1 = require("./log-fetcher");
class FundingRateScheduler {
    constructor(config = {}) {
        this.intervalId = null;
        this.isRunning = false;
        this.config = {
            intervalMinutes: 60, // Default: fetch every hour
            baseDir: './logs',
            autoStart: false,
            ...config
        };
    }
    /**
     * Start the scheduler
     */
    start() {
        if (this.isRunning) {
            console.log('Scheduler is already running');
            return;
        }
        console.log(`Starting funding rate scheduler - fetching every ${this.config.intervalMinutes} minutes`);
        // Fetch immediately on start
        this.executeFetch();
        // Set up recurring fetch
        const intervalMs = this.config.intervalMinutes * 60 * 1000;
        this.intervalId = setInterval(() => {
            this.executeFetch();
        }, intervalMs);
        this.isRunning = true;
        console.log('Scheduler started successfully');
    }
    /**
     * Stop the scheduler
     */
    stop() {
        if (!this.isRunning) {
            console.log('Scheduler is not running');
            return;
        }
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
        this.isRunning = false;
        console.log('Scheduler stopped');
    }
    /**
     * Execute a single fetch operation
     */
    async executeFetch() {
        try {
            console.log(`[${new Date().toISOString()}] Starting scheduled fetch...`);
            const result = await log_fetcher_1.logFetcher.fetchAndSave(this.config.baseDir);
            if (result.success) {
                console.log(`[${new Date().toISOString()}] Fetch completed successfully: ${result.filename}`);
                this.config.onFetchComplete?.(result);
            }
            else {
                console.error(`[${new Date().toISOString()}] Fetch failed: ${result.error}`);
                this.config.onError?.(new Error(result.error || 'Unknown fetch error'));
            }
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error(`[${new Date().toISOString()}] Unexpected error during fetch:`, errorMessage);
            this.config.onError?.(error instanceof Error ? error : new Error(errorMessage));
        }
    }
    /**
     * Perform a manual fetch (outside of schedule)
     */
    async manualFetch() {
        console.log('Performing manual fetch...');
        return await log_fetcher_1.logFetcher.fetchAndSave(this.config.baseDir);
    }
    /**
     * Get scheduler status
     */
    getStatus() {
        const nextFetchTime = this.isRunning && this.intervalId
            ? new Date(Date.now() + this.config.intervalMinutes * 60 * 1000)
            : undefined;
        return {
            isRunning: this.isRunning,
            intervalMinutes: this.config.intervalMinutes,
            baseDir: this.config.baseDir,
            nextFetchTime
        };
    }
    /**
     * Update configuration (requires restart if running)
     */
    updateConfig(newConfig) {
        const wasRunning = this.isRunning;
        if (wasRunning) {
            this.stop();
        }
        this.config = { ...this.config, ...newConfig };
        if (wasRunning) {
            this.start();
        }
        console.log('Scheduler configuration updated');
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
}
exports.FundingRateScheduler = FundingRateScheduler;
exports.fundingRateScheduler = new FundingRateScheduler();
//# sourceMappingURL=scheduler.js.map