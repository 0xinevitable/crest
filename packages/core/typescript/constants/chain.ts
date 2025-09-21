import { defineChain } from 'viem';

export const hyperliquidEvmTestnet = defineChain({
  id: 998,
  name: 'Hyperliquid EVM Testnet',
  nativeCurrency: { name: 'HYPE', symbol: 'HYPE', decimals: 18 },
  rpcUrls: {
    default: {
      http: ['https://evmrpc-jp.hyperpc.app/2a850a8987744037bc1fce0b59f22e1b'],
    },
  },
  testnet: true,
});
