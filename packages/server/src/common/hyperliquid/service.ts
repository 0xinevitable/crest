import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

import { Network } from '@crest/database';

import { EnvService } from '@/common/env';

import type {
  SpotMetaResponse,
  MetaResponse,
  PredictedFundingData,
  HlPerpData,
} from './types';

@Injectable()
export class HyperliquidService {
  private readonly logger = new Logger(HyperliquidService.name);

  constructor(
    private readonly httpService: HttpService,
    private readonly envService: EnvService,
  ) {}

  private getBaseUrl(network: Network): string {
    const { HYPERLIQUID_MAINNET_API_URL, HYPERLIQUID_TESTNET_API_URL } =
      this.envService.get();
    return network === Network.Mainnet
      ? HYPERLIQUID_MAINNET_API_URL
      : HYPERLIQUID_TESTNET_API_URL;
  }

  private async requestInfo<T extends object>(
    request: { type: string },
    network: Network,
  ): Promise<T> {
    const baseUrl = this.getBaseUrl(network);
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${baseUrl}/info`, request, {
          headers: { 'Content-Type': 'application/json' },
        }),
      );
      return response.data;
    } catch (error) {
      this.logger.error(
        `Failed to request info for type: ${request.type}`,
        error,
      );
      throw error;
    }
  }

  async getSpotIndex({
    symbol,
    network = Network.Mainnet,
  }: {
    symbol: string;
    network?: Network;
  }) {
    const { tokens, universe } = await this.requestInfo<SpotMetaResponse>(
      {
        type: 'spotMeta',
      },
      network,
    );

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

  async getPerpIndex({
    symbol,
    network = Network.Mainnet,
  }: {
    symbol: string;
    network?: Network;
  }) {
    const { universe } = await this.requestInfo<MetaResponse>(
      {
        type: 'meta',
      },
      network,
    );

    const perpIndex = universe.findIndex((asset) => asset.name === symbol);
    if (perpIndex === -1) {
      throw new Error(`Perpetual ${symbol} not found`);
    }

    return { perpIndex, meta: universe[perpIndex] };
  }

  async getIndexesBySymbol({
    symbol,
    network = Network.Mainnet,
  }: {
    symbol: string;
    network?: Network;
  }) {
    const [spot, perp] = await Promise.all([
      this.getSpotIndex({ symbol, network }),
      this.getPerpIndex({ symbol, network }),
    ]);

    return {
      symbol,
      tokenIndex: spot.tokenIndex,
      spotIndex: spot.spotIndex,
      perpIndex: perp.perpIndex,
    };
  }

  async fetchPredictedFundings({
    network = Network.Mainnet,
  }: { network?: Network } = {}): Promise<{
    rawData: PredictedFundingData[];
    hlPerpData: HlPerpData[];
  }> {
    try {
      const rawData = await this.requestInfo<PredictedFundingData[]>(
        {
          type: 'predictedFundings',
        },
        network,
      );

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