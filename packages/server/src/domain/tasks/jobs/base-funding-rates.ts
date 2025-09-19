import { Injectable, Logger } from '@nestjs/common';

import { Network } from '@crest/database';

import { HyperliquidService } from '@/common/hyperliquid';

import { FundingDataProcessorService } from '../services/funding-data-processor';
import { FundingDataStorageService } from '../services/funding-data-storage';

@Injectable()
export abstract class BaseFundingRatesJob {
  protected readonly logger = new Logger(this.constructor.name);

  constructor(
    protected readonly hyperliquidService: HyperliquidService,
    protected readonly dataProcessor: FundingDataProcessorService,
    protected readonly dataStorage: FundingDataStorageService,
  ) {}

  protected abstract getNetwork(): Network;

  protected async fetchAndSaveFundingData(): Promise<void> {
    const network = this.getNetwork();

    try {
      this.logger.log(`Starting scheduled ${network} funding data fetch`);

      const { rawData, hlPerpData } =
        await this.hyperliquidService.fetchPredictedFundings({ network });

      await Promise.all([
        this.dataStorage.saveRawData(rawData, network),
        this.dataProcessor.processFundingData(hlPerpData, network),
      ]);

      this.logger.log(
        `Successfully completed ${network} funding data fetch and save`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to fetch and save ${network} funding data`,
        error,
      );
    }
  }
}
