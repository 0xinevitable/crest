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

export const hyperliquidEvmMainnet = defineChain({
  id: 999,
  name: 'Hyperliquid',
  nativeCurrency: {
    name: 'HYPE',
    symbol: 'HYPE',
    decimals: 18,
  },
  blockExplorers: {
    default: {
      name: 'HyperEVMScan',
      url: 'https://hyperevmscan.io',
    },
  },
  rpcUrls: {
    default: {
      http: ['https://rpc.hyperliquid.xyz/evm'],
    },
  },
  contracts: {
    multicall3: {
      address: '0xcA11bde05977b3631167028862bE2a173976CA11',
      blockCreated: 1,
    },
  },
});
