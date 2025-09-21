import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'viem';
import { hyperliquidEvmTestnet } from 'viem/chains';

export const wagmiConfig = getDefaultConfig({
  appName: 'Crest',
  projectId: 'e41e817bfd4e2b5c929670379c5bfa61',
  chains: [hyperliquidEvmTestnet],
  transports: {
    [hyperliquidEvmTestnet.id]: http(),
  },
});
