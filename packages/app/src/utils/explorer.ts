import { Address } from 'viem';
import { hyperliquidMainnet } from '@/constants/chains';

// Force use mainnet explorer
const EXPLORER_BASE_URL = hyperliquidMainnet.blockExplorers?.default.url;

export const Explorer = {
  getTxLink: (hash: string) => `${EXPLORER_BASE_URL}/tx/${hash}`,
  getAccountLink: (address?: string | Address) =>
    `${EXPLORER_BASE_URL}/address/${address}`,
};
