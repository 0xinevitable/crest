import { Controller, Post } from '@nestjs/common';

import { FundingRatesJob } from './jobs';

@Controller('tasks')
export class TasksController {
  constructor(private readonly fundingRatesJob: FundingRatesJob) {}

  @Post('funding-rates')
  async triggerFundingRatesJob() {
    await this.fundingRatesJob.fetchAndSaveFundingData();
    return { message: 'Funding rates job executed successfully' };
  }
}
