import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

import type {
  SpotMetaResponse,
  MetaResponse,
  PredictedFundingData,
  HlPerpData,
} from './types';

@Injectable()
export class HyperliquidService {
  private readonly logger = new Logger(HyperliquidService.name);
  private readonly baseUrl = 'https://api.hyperliquid.xyz';

  constructor(private readonly httpService: HttpService) {}

  private async requestInfo<T extends object>(request: { type: string }): Promise<T> {
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${this.baseUrl}/info`, request, {
          headers: { 'Content-Type': 'application/json' },
        }),
      );
      return response.data;
    } catch (error) {
      this.logger.error(`Failed to request info for type: ${request.type}`, error);
      throw error;
    }
  }

  async getSpotIndex(symbol: string) {
    const { tokens, universe } = await this.requestInfo<SpotMetaResponse>({
      type: 'spotMeta',
    });

    const token = tokens.find((token) => token.name === symbol);
    if (token?.index === undefined) {
      throw new Error(`Token ${symbol} not found`);
    }

    const spot = universe.find((asset) => asset.tokens[0] === token.index);
    if (spot?.index === undefined) {
      throw new Error(`Spot ${symbol} not found`);
    }

    return {
      tokenIndex: token.index,
      spotIndex: spot.index,
      meta: { token, spot },
    };
  }

  async getPerpIndex(symbol: string) {
    const { universe } = await this.requestInfo<MetaResponse>({
      type: 'meta',
    });

    const perpIndex = universe.findIndex((asset) => asset.name === symbol);
    if (perpIndex === -1) {
      throw new Error(`Perpetual ${symbol} not found`);
    }

    return { perpIndex, meta: universe[perpIndex] };
  }

  async getIndexesBySymbol(symbol: string) {
    const [spot, perp] = await Promise.all([
      this.getSpotIndex(symbol),
      this.getPerpIndex(symbol),
    ]);

    return {
      symbol,
      tokenIndex: spot.tokenIndex,
      spotIndex: spot.spotIndex,
      perpIndex: perp.perpIndex,
    };
  }

  async fetchPredictedFundings(): Promise<{
    rawData: PredictedFundingData[];
    hlPerpData: HlPerpData[];
  }> {
    try {
      const rawData = await this.requestInfo<PredictedFundingData[]>({
        type: 'predictedFundings',
      });

      const hlPerpData: HlPerpData[] = rawData.reduce<HlPerpData[]>(
        (acc, [ticker, exchanges]) => {
          const hlPerpEntry = exchanges.find(
            ([exchangeName]) => exchangeName === 'HlPerp',
          );
          if (hlPerpEntry && hlPerpEntry[1]) {
            acc.push({ ticker, fundingRate: hlPerpEntry[1].fundingRate });
          }
          return acc;
        },
        [],
      );

      this.logger.log(`Fetched ${hlPerpData.length} HlPerp funding entries`);
      return { rawData, hlPerpData };
    } catch (error) {
      this.logger.error('Failed to fetch predicted fundings from API', error);
      throw error;
    }
  }
}