import { Injectable, Logger, Inject } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

import { EnvService } from '@/common/env';
import { DatabaseService } from '@/common/database';
import { S3_CLIENT } from '@/common/object-storage';
import {
  HyperliquidService,
  type PredictedFundingData,
  type HlPerpData,
} from '@/common/hyperliquid';

@Injectable()
export class FundingRatesJob {
  private readonly logger = new Logger(FundingRatesJob.name);
  private readonly bucket: string;

  constructor(
    private readonly hyperliquidService: HyperliquidService,
    private readonly envService: EnvService,
    private readonly databaseService: DatabaseService,
    @Inject(S3_CLIENT) private readonly s3Client: S3Client,
  ) {
    const { S3_BUCKET } = this.envService.get();
    this.bucket = S3_BUCKET;
  }

  @Cron(CronExpression.EVERY_HOUR)
  async fetchAndSaveFundingData(): Promise<void> {
    try {
      this.logger.log('Starting scheduled funding data fetch');

      const { rawData, hlPerpData } =
        await this.hyperliquidService.fetchPredictedFundings();

      await Promise.all([
        this.saveRawData(rawData),
        this.processFundingData(hlPerpData),
      ]);

      this.logger.log('Successfully completed funding data fetch and save');
    } catch (error) {
      this.logger.error('Failed to fetch and save funding data', error);
    }
  }

  private async saveRawData(rawData: PredictedFundingData[]): Promise<void> {
    try {
      const timestamp = new Date().toISOString();
      const key = `funding-rates/raw/${timestamp}.json`;

      const jsonString = JSON.stringify(rawData, null, 2);

      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: jsonString,
          ContentType: 'application/json',
        }),
      );

      this.logger.log(`Saved raw funding data to ${key}`);
    } catch (error) {
      this.logger.error(`Failed to save raw data: ${(error as Error).message}`);
      throw error;
    }
  }

  private async processFundingData(fundingData: HlPerpData[]): Promise<void> {
    try {
      const readingTime = new Date();
      const fundingRateEntries = fundingData.map(({ ticker, fundingRate }) => ({
        ticker,
        fundingRate,
        readingTime,
      }));

      await this.databaseService.fundingRates.createMany({
        data: fundingRateEntries,
        skipDuplicates: true,
      });

      this.logger.log(
        `Successfully saved ${fundingRateEntries.length} funding rate entries`,
      );
    } catch (error) {
      this.logger.error('Failed to process funding data', error);
      throw error;
    }
  }
}
