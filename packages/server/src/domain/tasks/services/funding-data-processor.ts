import { Injectable, Logger } from '@nestjs/common';

import { Network } from '@crest/database';

import { DatabaseService } from '@/common/database';
import type { HlPerpData } from '@/common/hyperliquid';

@Injectable()
export class FundingDataProcessorService {
  private readonly logger = new Logger(FundingDataProcessorService.name);

  constructor(private readonly databaseService: DatabaseService) {}

  async processFundingData(
    fundingData: HlPerpData[],
    network: Network,
  ): Promise<void> {
    try {
      const readingTime = new Date();
      const fundingRateEntries = fundingData.map(({ ticker, fundingRate }) => ({
        ticker,
        fundingRate,
        readingTime,
        network,
      }));

      await this.databaseService.fundingRates.createMany({
        data: fundingRateEntries,
        skipDuplicates: true,
      });

      this.logger.log(
        `Successfully saved ${fundingRateEntries.length} ${network} funding rate entries`,
      );
    } catch (error) {
      this.logger.error(`Failed to process ${network} funding data`, error);
      throw error;
    }
  }
}
