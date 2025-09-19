import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { Network } from '@crest/database';

import { HyperliquidService } from '@/common/hyperliquid';

import { FundingDataProcessorService } from '../services/funding-data-processor';
import { FundingDataStorageService } from '../services/funding-data-storage';
import { BaseFundingRatesJob } from './base-funding-rates';

@Injectable()
export class MainnetFundingRatesJob extends BaseFundingRatesJob {
  constructor(
    hyperliquidService: HyperliquidService,
    dataProcessor: FundingDataProcessorService,
    dataStorage: FundingDataStorageService,
  ) {
    super(hyperliquidService, dataProcessor, dataStorage);
  }

  protected getNetwork(): Network {
    return Network.Mainnet;
  }

  @Cron(CronExpression.EVERY_HOUR)
  async scheduledFetch(): Promise<void> {
    await this.fetchAndSaveFundingData();
  }
}
