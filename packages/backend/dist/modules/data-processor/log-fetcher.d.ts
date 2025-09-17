export interface LogFetcherConfig {
    hyperliquidApiUrl: string;
    retryAttempts: number;
    retryDelayMs: number;
    requestTimeoutMs: number;
}
export interface FetchResult {
    success: boolean;
    filename?: string;
    filepath?: string;
    error?: string;
    recordCount?: number;
    timestamp?: Date;
}
export declare class LogFetcher {
    private config;
    constructor(config?: Partial<LogFetcherConfig>);
    /**
     * Fetch funding rates from Hyperliquid API and save to filesystem
     */
    fetchAndSave(baseDir?: string): Promise<FetchResult>;
    /**
     * Fetch funding rates from API with retry logic
     */
    private fetchWithRetry;
    /**
     * Generate filename with timestamp
     */
    private generateFilename;
    /**
     * Simple delay utility
     */
    private delay;
    /**
     * Test API connectivity
     */
    testConnection(): Promise<boolean>;
    /**
     * Get current configuration
     */
    getConfig(): LogFetcherConfig;
    /**
     * Update configuration
     */
    updateConfig(newConfig: Partial<LogFetcherConfig>): void;
}
export declare const logFetcher: LogFetcher;
//# sourceMappingURL=log-fetcher.d.ts.map