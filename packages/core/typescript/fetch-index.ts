class HyperliquidAPI {
  baseUrl: string;
  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async _requestInfo<T extends object>(request: { type: string }): Promise<T> {
    const response = await fetch(`${this.baseUrl}/info`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request),
    });
    return response.json();
  }

  async _getSpotIndex(symbol: string) {
    const { tokens, universe } = await this._requestInfo<{
      tokens: { name: string; index: number }[];
      universe: {
        index: number;
        tokens: [tokenIndex: number, quoteTokenIndex: number];
      }[];
    }>({ type: 'spotMeta' });

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

  async _getPerpIndex(symbol: string) {
    const { universe } = await this._requestInfo<{
      universe: {
        szDecimals: number;
        name: string;
        maxLeverage: number;
        marginTableId: number;
      }[];
    }>({ type: 'meta' });

    const perpIndex = universe.findIndex((asset) => asset.name === symbol);
    return { perpIndex, meta: universe[perpIndex] };
  }

  async getIndexesBySymbol(symbol: string) {
    const spot = await this._getSpotIndex(symbol);
    const perp = await this._getPerpIndex(symbol);
    return {
      symbol,
      tokenIndex: spot.tokenIndex,
      spotIndex: spot.spotIndex,
      perpIndex: perp.perpIndex,

      tokenMeta: spot.meta.token,
      spotMeta: spot.meta.spot,
      perpMeta: perp.meta,
    };
  }
}

const main = async () => {
  console.log('===== MAINNET =====');
  const hl = new HyperliquidAPI('https://api.hyperliquid.xyz');
  {
    const indexes = await hl.getIndexesBySymbol('HYPE');
    console.log(indexes);
  }
  {
    const indexes = await hl.getIndexesBySymbol('PURR');
    console.log(indexes);
  }
  {
    const indexes = await hl.getIndexesBySymbol('USDT0');
    console.log(indexes);
  }

  console.log('===== TESTNET =====');
  const testnet = new HyperliquidAPI('https://api.hyperliquid-testnet.xyz');
  {
    const indexes = await testnet.getIndexesBySymbol('HYPE');
    console.log(indexes);
  }
  {
    const indexes = await testnet.getIndexesBySymbol('PURR');
    console.log(indexes);
  }
  {
    const indexes = await testnet.getIndexesBySymbol('TZERO'); // USDT0
    console.log(indexes);
  }
};

main();

export {};
