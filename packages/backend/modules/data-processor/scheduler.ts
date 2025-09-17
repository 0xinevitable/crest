import { logFetcher, FetchResult } from './log-fetcher';

export interface SchedulerConfig {
  intervalMinutes: number;
  baseDir: string;
  autoStart: boolean;
  onFetchComplete?: (result: FetchResult) => void;
  onError?: (error: Error) => void;
}

export class FundingRateScheduler {
  private config: SchedulerConfig;
  private intervalId: NodeJS.Timeout | null = null;
  private isRunning = false;

  constructor(config: Partial<SchedulerConfig> = {}) {
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
  start(): void {
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
  stop(): void {
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
  private async executeFetch(): Promise<void> {
    try {
      console.log(`[${new Date().toISOString()}] Starting scheduled fetch...`);
      const result = await logFetcher.fetchAndSave(this.config.baseDir);
      
      if (result.success) {
        console.log(`[${new Date().toISOString()}] Fetch completed successfully: ${result.filename}`);
        this.config.onFetchComplete?.(result);
      } else {
        console.error(`[${new Date().toISOString()}] Fetch failed: ${result.error}`);
        this.config.onError?.(new Error(result.error || 'Unknown fetch error'));
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error(`[${new Date().toISOString()}] Unexpected error during fetch:`, errorMessage);
      this.config.onError?.(error instanceof Error ? error : new Error(errorMessage));
    }
  }

  /**
   * Perform a manual fetch (outside of schedule)
   */
  async manualFetch(): Promise<FetchResult> {
    console.log('Performing manual fetch...');
    return await logFetcher.fetchAndSave(this.config.baseDir);
  }

  /**
   * Get scheduler status
   */
  getStatus(): {
    isRunning: boolean;
    intervalMinutes: number;
    baseDir: string;
    nextFetchTime?: Date;
  } {
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
  updateConfig(newConfig: Partial<SchedulerConfig>): void {
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
  getConfig(): SchedulerConfig {
    return { ...this.config };
  }
}

export const fundingRateScheduler = new FundingRateScheduler();