import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'viem';
import { hyperliquidMainnet } from './chains';

// Force use mainnet for now
export const wagmiConfig = getDefaultConfig({
  appName: 'Crest',
  projectId: 'e41e817bfd4e2b5c929670379c5bfa61',
  chains: [hyperliquidMainnet],
  transports: {
    [hyperliquidMainnet.id]: http(),
  },
});
