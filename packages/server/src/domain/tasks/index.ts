import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ScheduleModule } from '@nestjs/schedule';

import { DatabaseModule } from '@/common/database';
import { ObjectStorageModule } from '@/common/object-storage';
import { HyperliquidModule } from '@/common/hyperliquid';

import { FundingRatesJob } from './jobs';
import { TasksController } from './controller';

@Module({
  imports: [
    HttpModule,
    ScheduleModule.forRoot(),
    DatabaseModule,
    ObjectStorageModule,
    HyperliquidModule,
  ],
  providers: [FundingRatesJob],
  controllers: [TasksController],
})
class TasksModule {}

export { TasksModule };
