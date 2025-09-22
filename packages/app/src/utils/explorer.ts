import { Address } from 'viem';

import { hyperliquidEvmTestnet } from '@/constants/chains';

const EXPLORER_BASE_URL = hyperliquidEvmTestnet.blockExplorers?.default.url;

export const Explorer = {
  getTxLink: (hash: string) => `${EXPLORER_BASE_URL}/tx/${hash}`,
  getAccountLink: (address?: string | Address) =>
    `${EXPLORER_BASE_URL}/address/${address}`,
};
