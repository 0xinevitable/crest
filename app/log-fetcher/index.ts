#!/usr/bin/env node

import { logFetcher } from '../../modules/data-processor/log-fetcher';
import { fundingRateScheduler } from '../../modules/data-processor/scheduler';
import { fileUtils } from '../../modules/utils/file-utils';

interface AppConfig {
  mode: 'once' | 'schedule';
  intervalMinutes?: number;
  outputDir?: string;
  testConnection?: boolean;
}

class FundingRateFetcher {
  private config: AppConfig;

  constructor() {
    this.config = this.parseArguments();
  }

  async run(): Promise<void> {
    console.log('🚀 Funding Rate Fetcher Starting...');
    console.log('Configuration:', this.config);

    try {
      // Test connection if requested
      if (this.config.testConnection) {
        console.log('\n🔍 Testing API connection...');
        const connected = await logFetcher.testConnection();
        if (connected) {
          console.log('✅ API connection successful');
        } else {
          console.log('❌ API connection failed');
          process.exit(1);
        }
      }

      // Ensure output directory exists
      if (this.config.outputDir) {
        await fileUtils.ensureDirectory(this.config.outputDir);
        console.log(`📁 Output directory: ${this.config.outputDir}`);
      }

      if (this.config.mode === 'once') {
        await this.runOnce();
      } else {
        await this.runScheduled();
      }
    } catch (error) {
      console.error('💥 Application error:', error instanceof Error ? error.message : 'Unknown error');
      process.exit(1);
    }
  }

  private async runOnce(): Promise<void> {
    console.log('\n📥 Fetching funding rates (one-time)...');
    
    const result = await logFetcher.fetchAndSave(this.config.outputDir || './logs');
    
    if (result.success) {
      console.log(`✅ Success! Saved ${result.recordCount} records to ${result.filename}`);
    } else {
      console.log(`❌ Failed: ${result.error}`);
      process.exit(1);
    }
  }

  private async runScheduled(): Promise<void> {
    console.log(`\n⏰ Starting scheduled fetching (every ${this.config.intervalMinutes} minutes)...`);
    
    // Configure scheduler
    fundingRateScheduler.updateConfig({
      intervalMinutes: this.config.intervalMinutes || 60,
      baseDir: this.config.outputDir || './logs',
      onFetchComplete: (result) => {
        console.log(`✅ Scheduled fetch completed: ${result.filename} (${result.recordCount} records)`);
      },
      onError: (error) => {
        console.error(`❌ Scheduled fetch error: ${error.message}`);
      }
    });

    // Start scheduler
    fundingRateScheduler.start();

    // Handle graceful shutdown
    process.on('SIGINT', () => {
      console.log('\n🛑 Shutting down scheduler...');
      fundingRateScheduler.stop();
      process.exit(0);
    });

    process.on('SIGTERM', () => {
      console.log('\n🛑 Shutting down scheduler...');
      fundingRateScheduler.stop();
      process.exit(0);
    });

    console.log('🔄 Scheduler running. Press Ctrl+C to stop.');
  }

  private parseArguments(): AppConfig {
    const args = process.argv.slice(2);
    const config: AppConfig = {
      mode: 'once' // default mode
    };

    for (let i = 0; i < args.length; i++) {
      const arg = args[i];
      
      switch (arg) {
        case '--schedule':
        case '-s':
          config.mode = 'schedule';
          break;
          
        case '--interval':
        case '-i':
          const interval = parseInt(args[++i]);
          if (isNaN(interval) || interval <= 0) {
            throw new Error('Invalid interval value. Must be a positive number.');
          }
          config.intervalMinutes = interval;
          break;
          
        case '--output':
        case '-o':
          config.outputDir = args[++i];
          if (!config.outputDir) {
            throw new Error('Output directory is required when using --output flag.');
          }
          break;
          
        case '--test':
        case '-t':
          config.testConnection = true;
          break;
          
        case '--help':
        case '-h':
          this.showHelp();
          process.exit(0);
          break;
          
        default:
          if (arg.startsWith('-')) {
            throw new Error(`Unknown option: ${arg}`);
          }
      }
    }

    return config;
  }

  private showHelp(): void {
    console.log(`
🚀 Funding Rate Fetcher

USAGE:
  npm run fetch              # Fetch once and exit
  npm run fetch -- --schedule --interval 30    # Fetch every 30 minutes

OPTIONS:
  -s, --schedule            Run in scheduled mode (continuous fetching)
  -i, --interval <minutes>  Fetch interval in minutes (default: 60)
  -o, --output <directory>  Output directory for log files (default: ./logs)
  -t, --test               Test API connection before starting
  -h, --help               Show this help message

EXAMPLES:
  npm run fetch -- --test                    # Test connection and fetch once
  npm run fetch -- --schedule --interval 15  # Fetch every 15 minutes
  npm run fetch -- --output /data/logs       # Save to custom directory
`);
  }
}

// Run the application
if (require.main === module) {
  const app = new FundingRateFetcher();
  app.run().catch(console.error);
}