import { httpClient } from '../utils/http-client';
import { fileUtils } from '../utils/file-utils';
import { RawLogData } from './types/funding-rate';

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

export class LogFetcher {
  private config: LogFetcherConfig;

  constructor(config: Partial<LogFetcherConfig> = {}) {
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
  async fetchAndSave(baseDir: string = './logs'): Promise<FetchResult> {
    const timestamp = new Date();
    const filename = this.generateFilename(timestamp);
    const filepath = `${baseDir}/${filename}`;

    try {
      console.log('Fetching funding rates from Hyperliquid API...');
      const data = await this.fetchWithRetry();
      
      console.log(`Received ${data.length} symbols from API`);
      
      // Ensure directory exists
      await fileUtils.ensureDirectory(baseDir);
      
      // Save to file
      await fileUtils.writeJson(filepath, data);
      
      console.log(`Funding rates saved to ${filepath}`);
      
      return {
        success: true,
        filename,
        filepath,
        recordCount: data.length,
        timestamp
      };
    } catch (error) {
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
  private async fetchWithRetry(): Promise<RawLogData> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= this.config.retryAttempts; attempt++) {
      try {
        console.log(`Attempt ${attempt}/${this.config.retryAttempts}: Fetching from ${this.config.hyperliquidApiUrl}`);
        
        const response = await httpClient.post<RawLogData>(
          this.config.hyperliquidApiUrl,
          { type: 'predictedFundings' },
          {
            'Content-Type': 'application/json'
          }
        );

        if (!Array.isArray(response.data)) {
          throw new Error('Invalid response format: expected array');
        }

        console.log(`Successfully fetched data on attempt ${attempt}`);
        return response.data;
      } catch (error) {
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
  private generateFilename(timestamp: Date): string {
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
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Test API connectivity
   */
  async testConnection(): Promise<boolean> {
    try {
      const response = await httpClient.post<RawLogData>(
        this.config.hyperliquidApiUrl,
        { type: 'predictedFundings' }
      );
      
      return Array.isArray(response.data) && response.data.length > 0;
    } catch (error) {
      console.error('Connection test failed:', error instanceof Error ? error.message : 'Unknown error');
      return false;
    }
  }

  /**
   * Get current configuration
   */
  getConfig(): LogFetcherConfig {
    return { ...this.config };
  }

  /**
   * Update configuration
   */
  updateConfig(newConfig: Partial<LogFetcherConfig>): void {
    this.config = { ...this.config, ...newConfig };
  }
}

export const logFetcher = new LogFetcher();