import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'viem';
import { hyperliquidEvmTestnet } from 'viem/chains';
import { hyperliquidMainnet } from './chains';
import { Config } from '../utils/config';

const isProduction = Config.ENVIRONMENT === 'production';

export const wagmiConfig = getDefaultConfig({
  appName: 'Crest',
  projectId: 'e41e817bfd4e2b5c929670379c5bfa61',
  chains: isProduction ? [hyperliquidMainnet] : [hyperliquidEvmTestnet],
  transports: isProduction ? {
    [hyperliquidMainnet.id]: http(),
  } : {
    [hyperliquidEvmTestnet.id]: http(),
  },
});
