# Funding Rate Fetcher

A TypeScript application for fetching cryptocurrency funding rates from the Hyperliquid API and storing them locally.

## Features

- ✅ Fetch funding rates from Hyperliquid API
- ✅ Store data as timestamped JSON files
- ✅ Periodic scheduling with configurable intervals
- ✅ Error handling and retry logic
- ✅ Command-line interface
- ✅ Connection testing
- ✅ TypeScript support

## Quick Start

### Install Dependencies

```bash
npm install
```

### Fetch Once

```bash
npm run fetch
```

### Scheduled Fetching

```bash
# Fetch every hour (default)
npm run fetch -- --schedule

# Fetch every 15 minutes
npm run fetch -- --schedule --interval 15
```

### Test Connection

```bash
npm run fetch -- --test
```

## Usage Examples

```bash
# Basic one-time fetch
npm run fetch

# Test API connection and fetch once
npm run fetch -- --test

# Scheduled fetching every 30 minutes
npm run fetch -- --schedule --interval 30

# Custom output directory
npm run fetch -- --output /data/funding-logs

# Combined options
npm run fetch -- --schedule --interval 60 --output ./custom-logs --test
```

## Command Line Options

| Option                 | Alias | Description                  | Default  |
| ---------------------- | ----- | ---------------------------- | -------- |
| `--schedule`           | `-s`  | Run in scheduled mode        | One-time |
| `--interval <minutes>` | `-i`  | Fetch interval in minutes    | 60       |
| `--output <directory>` | `-o`  | Output directory             | `./logs` |
| `--test`               | `-t`  | Test connection before start | false    |
| `--help`               | `-h`  | Show help message            | -        |

## File Structure

```
📦 crest-backend
├── 📁 app/
│   └── 📁 log-fetcher/
│       └── 📄 index.ts          # Main CLI application
├── 📁 modules/
│   ├── 📁 data-processor/
│   │   ├── 📄 log-fetcher.ts    # API fetching logic
│   │   ├── 📄 scheduler.ts      # Periodic scheduling
│   │   └── 📁 types/
│   │       └── 📄 funding-rate.ts # Type definitions
│   ├── 📁 utils/
│   │   ├── 📄 file-utils.ts     # File operations
│   │   └── 📄 http-client.ts    # HTTP client
│   └── 📁 database/
│       └── 📄 schema.sql        # Database schema
└── 📁 logs/                     # Output directory
    └── 📄 YYYYMMDDHHMM-funding-rates.json
```

## Data Format

The fetched data contains funding rates for multiple exchanges:

```json
[
  [
    "BTC",
    [
      [
        "BinPerp",
        {
          "fundingRate": "0.00007652",
          "nextFundingTime": 1758124800000,
          "fundingIntervalHours": 8
        }
      ],
      [
        "HlPerp",
        {
          "fundingRate": "0.0000125",
          "nextFundingTime": 1758103200000,
          "fundingIntervalHours": 1
        }
      ],
      [
        "BybitPerp",
        {
          "fundingRate": "0.0001",
          "nextFundingTime": 1758124800000,
          "fundingIntervalHours": 8
        }
      ]
    ]
  ]
]
```

## Configuration

### Environment Variables

No environment variables required - the application uses the public Hyperliquid API.

### Programmatic Usage

```typescript
import { logFetcher } from './modules/data-processor/log-fetcher.js';
import { fundingRateScheduler } from './modules/data-processor/scheduler.js';

// One-time fetch
const result = await logFetcher.fetchAndSave('./logs');

// Scheduled fetching
fundingRateScheduler.updateConfig({
  intervalMinutes: 30,
  baseDir: './logs',
});
fundingRateScheduler.start();
```

## Error Handling

- **API Connection Issues**: Automatic retry with exponential backoff
- **File System Errors**: Directory creation and permission handling
- **Network Timeouts**: Configurable timeout with abort controller
- **Invalid Data**: Response validation and error reporting

## Development

```bash
# Type checking
npm run typecheck

# Build
npm run build

# Development mode
npm run dev
```

## Next Steps

1. Set up database ingestion using the provided schema
2. Configure automated scheduling (cron/systemd)
3. Add monitoring and alerting
4. Implement data processing and analysis

## API Information

- **Endpoint**: `https://api-ui.hyperliquid.xyz/info`
- **Method**: POST
- **Payload**: `{"type": "predictedFundings"}`
- **Rate Limits**: None specified
- **Authentication**: None required
