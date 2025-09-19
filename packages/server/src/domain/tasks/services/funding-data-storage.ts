import { Injectable, Logger, Inject } from '@nestjs/common';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

import { Network } from '@crest/database';

import { EnvService } from '@/common/env';
import { S3_CLIENT } from '@/common/object-storage';
import type { PredictedFundingData } from '@/common/hyperliquid';

@Injectable()
export class FundingDataStorageService {
  private readonly logger = new Logger(FundingDataStorageService.name);
  private readonly bucket: string;

  constructor(
    private readonly envService: EnvService,
    @Inject(S3_CLIENT) private readonly s3Client: S3Client,
  ) {
    const { S3_BUCKET } = this.envService.get();
    this.bucket = S3_BUCKET;
  }

  async saveRawData(
    rawData: PredictedFundingData[],
    network: Network,
  ): Promise<void> {
    try {
      const timestamp = new Date().toISOString();
      const key = `funding-rates/${network.toLowerCase()}/${timestamp}.json`;

      const jsonString = JSON.stringify(rawData, null, 2);

      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: jsonString,
          ContentType: 'application/json',
        }),
      );

      this.logger.log(`Saved raw ${network} funding data to ${key}`);
    } catch (error) {
      this.logger.error(
        `Failed to save raw ${network} data: ${(error as Error).message}`,
      );
      throw error;
    }
  }
}
