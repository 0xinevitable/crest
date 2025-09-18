import {
  Module,
  OnModuleInit,
  Inject,
  Logger,
  Injectable,
} from '@nestjs/common';
import {
  S3Client,
  CreateBucketCommand,
  HeadBucketCommand,
} from '@aws-sdk/client-s3';

import { EnvModule, EnvService } from '@/common/env';

const S3_CLIENT = Symbol('S3_CLIENT');

@Injectable()
class ObjectStorageModuleInit implements OnModuleInit {
  private readonly logger = new Logger(ObjectStorageModuleInit.name);

  constructor(
    @Inject(S3_CLIENT) private readonly s3Client: S3Client,
    private readonly envService: EnvService,
  ) {}

  async onModuleInit() {
    const { S3_BUCKET } = this.envService.get();

    try {
      await this.s3Client.send(new HeadBucketCommand({ Bucket: S3_BUCKET }));
      this.logger.log(`S3 bucket exists: ${S3_BUCKET}`);
    } catch (error) {
      if (
        (error as any).name === 'NotFound' ||
        (error as any).Code === 'NoSuchBucket'
      ) {
        try {
          await this.s3Client.send(
            new CreateBucketCommand({ Bucket: S3_BUCKET }),
          );
          this.logger.log(`Created S3 bucket: ${S3_BUCKET}`);
        } catch (createError) {
          this.logger.error(
            `Failed to create S3 bucket: ${(createError as Error).message}`,
          );
          throw createError;
        }
      } else {
        throw error;
      }
    }
  }
}

@Module({
  imports: [EnvModule],
  providers: [
    {
      provide: S3_CLIENT,
      useFactory: (envService: EnvService): S3Client => {
        const { S3_ENDPOINT, S3_ACCESS_KEY, S3_SECRET_KEY } = envService.get();
        return new S3Client({
          endpoint: S3_ENDPOINT,
          credentials: {
            accessKeyId: S3_ACCESS_KEY,
            secretAccessKey: S3_SECRET_KEY,
          },
          region: 'us-east-1',
          forcePathStyle: true,
          tls: false,
        });
      },
      inject: [EnvService],
    },
    ObjectStorageModuleInit,
  ],
  exports: [S3_CLIENT],
})
class ObjectStorageModule {}

export { ObjectStorageModule, S3_CLIENT };
