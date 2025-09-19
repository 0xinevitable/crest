import { Controller, Post, Body } from '@nestjs/common';

import { MainnetFundingRatesJob, TestnetFundingRatesJob } from './jobs';

interface TriggerJobDto {
  network?: 'mainnet' | 'testnet';
}

@Controller('tasks')
export class TasksController {
  constructor(
    private readonly mainnetFundingRatesJob: MainnetFundingRatesJob,
    private readonly testnetFundingRatesJob: TestnetFundingRatesJob,
  ) {}

  @Post('funding-rates')
  async triggerFundingRatesJob(@Body() body: TriggerJobDto) {
    const selectedNetwork = body.network || 'mainnet';

    if (selectedNetwork === 'testnet') {
      await this.testnetFundingRatesJob.scheduledFetch();
    } else {
      await this.mainnetFundingRatesJob.scheduledFetch();
    }

    return {
      message: `${selectedNetwork} funding rates job executed successfully`,
    };
  }
}
