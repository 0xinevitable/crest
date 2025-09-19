import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';

import { HyperliquidService } from './service';

@Module({
  imports: [HttpModule],
  providers: [HyperliquidService],
  exports: [HyperliquidService],
})
class HyperliquidModule {}

export { HyperliquidModule, HyperliquidService };
export type { PredictedFundingData, HlPerpData } from './types';
