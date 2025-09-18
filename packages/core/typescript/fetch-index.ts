class HyperliquidAPI {
  async _requestInfo<T extends object>(request: { type: string }): Promise<T> {
    const response = await fetch('https://api.hyperliquid.xyz/info', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request),
    });
    return response.json();
  }

  async getSpotIndex(symbol: string) {
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

  async getPerpIndex(symbol: string) {
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
}

const main = async () => {
  const hl = new HyperliquidAPI();

  const spot = await hl.getSpotIndex('HYPE');
  console.log(spot);
  const perp = await hl.getPerpIndex('HYPE');
  console.log(perp);
};

main();
