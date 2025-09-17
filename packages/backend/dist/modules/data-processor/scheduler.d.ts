import { FetchResult } from './log-fetcher';
export interface SchedulerConfig {
    intervalMinutes: number;
    baseDir: string;
    autoStart: boolean;
    onFetchComplete?: (result: FetchResult) => void;
    onError?: (error: Error) => void;
}
export declare class FundingRateScheduler {
    private config;
    private intervalId;
    private isRunning;
    constructor(config?: Partial<SchedulerConfig>);
    /**
     * Start the scheduler
     */
    start(): void;
    /**
     * Stop the scheduler
     */
    stop(): void;
    /**
     * Execute a single fetch operation
     */
    private executeFetch;
    /**
     * Perform a manual fetch (outside of schedule)
     */
    manualFetch(): Promise<FetchResult>;
    /**
     * Get scheduler status
     */
    getStatus(): {
        isRunning: boolean;
        intervalMinutes: number;
        baseDir: string;
        nextFetchTime?: Date;
    };
    /**
     * Update configuration (requires restart if running)
     */
    updateConfig(newConfig: Partial<SchedulerConfig>): void;
    /**
     * Get current configuration
     */
    getConfig(): SchedulerConfig;
}
export declare const fundingRateScheduler: FundingRateScheduler;
//# sourceMappingURL=scheduler.d.ts.map