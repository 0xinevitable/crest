import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { HyperliquidService } from '@/common/hyperliquid';
import { FundingDataProcessorService } from '../services/funding-data-processor';
import { FundingDataStorageService } from '../services/funding-data-storage';
import { BaseFundingRatesJob } from './base-funding-rates';
import { Network } from '@crest/database';

@Injectable()
export class TestnetFundingRatesJob extends BaseFundingRatesJob {
  constructor(
    hyperliquidService: HyperliquidService,
    dataProcessor: FundingDataProcessorService,
    dataStorage: FundingDataStorageService,
  ) {
    super(hyperliquidService, dataProcessor, dataStorage);
  }

  protected getNetwork(): Network {
    return Network.Testnet;
  }

  @Cron(CronExpression.EVERY_HOUR)
  async scheduledFetch(): Promise<void> {
    await this.fetchAndSaveFundingData();
  }
}
