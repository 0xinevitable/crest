import { Injectable, Inject, Logger } from '@nestjs/common';
import { S3Client, PutObjectCommand, CreateBucketCommand, HeadBucketCommand } from '@aws-sdk/client-s3';
import { EnvService } from '@/common/env';
import { S3_CLIENT } from './index';

@Injectable()
export class ObjectStorageService {
  private readonly logger = new Logger(ObjectStorageService.name);
  private readonly bucket: string;

  constructor(
    @Inject(S3_CLIENT) private readonly s3Client: S3Client,
    private readonly envService: EnvService,
  ) {
    const { S3_BUCKET } = this.envService.get();
    this.bucket = S3_BUCKET;
    this.ensureBucketExists();
  }

  private async ensureBucketExists(): Promise<void> {
    try {
      await this.s3Client.send(new HeadBucketCommand({ Bucket: this.bucket }));
    } catch (error) {
      if ((error as any).name === 'NotFound') {
        try {
          await this.s3Client.send(new CreateBucketCommand({ Bucket: this.bucket }));
          this.logger.log(`Created bucket: ${this.bucket}`);
        } catch (createError) {
          this.logger.error(`Failed to create bucket: ${(createError as Error).message}`);
        }
      }
    }
  }

  async saveJson(key: string, data: object): Promise<void> {
    try {
      const jsonString = JSON.stringify(data, null, 2);
      
      await this.s3Client.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: jsonString,
          ContentType: 'application/json',
        }),
      );
      
      this.logger.log(`Saved JSON to ${key}`);
    } catch (error) {
      this.logger.error(`Failed to save JSON to ${key}: ${(error as Error).message}`);
      throw error;
    }
  }
}