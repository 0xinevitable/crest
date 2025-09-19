import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ScheduleModule } from '@nestjs/schedule';

import { DatabaseModule } from '@/common/database';
import { ObjectStorageModule } from '@/common/object-storage';
import { HyperliquidModule } from '@/common/hyperliquid';

import {
  FundingRatesJob,
  MainnetFundingRatesJob,
  TestnetFundingRatesJob,
} from './jobs';
import {
  FundingDataProcessorService,
  FundingDataStorageService,
} from './services';
import { TasksController } from './controller';

@Module({
  imports: [
    DatabaseModule,
    ObjectStorageModule,
    ScheduleModule.forRoot(),
    HyperliquidModule,
  ],
  providers: [
    FundingDataProcessorService,
    FundingDataStorageService,

    FundingRatesJob,
    MainnetFundingRatesJob,
    TestnetFundingRatesJob,
  ],
  controllers: [TasksController],
})
class TasksModule {}

export { TasksModule };
