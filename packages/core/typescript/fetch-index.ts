class HyperliquidAPI {
  async getPerpIndex(symbol: string) {
    const response = await fetch('https://api.hyperliquid.xyz/info', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'meta' }),
    });
    const universe = (await response.json()).universe as {
      szDecimals: number;
      name: string;
      maxLeverage: number;
      marginTableId: number;
    }[];
    const perpIndex = universe.findIndex((asset) => asset.name === symbol);
    return { perpIndex, metadata: universe[perpIndex] };
  }
}

const main = async () => {
  const hl = new HyperliquidAPI();

  const meta = await hl.getPerpIndex('HYPE');
  console.log(meta);
};

main();
