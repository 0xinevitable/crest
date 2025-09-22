import { Address } from 'viem';
import { hyperliquidEvmTestnet } from 'viem/chains';
import { hyperliquidMainnet } from '@/constants/chains';
import { Config } from './config';

const currentChain = Config.NETWORK === 'mainnet' ? hyperliquidMainnet : hyperliquidEvmTestnet;
const EXPLORER_BASE_URL = currentChain.blockExplorers?.default.url;

export const Explorer = {
  getTxLink: (hash: string) => `${EXPLORER_BASE_URL}/tx/${hash}`,
  getAccountLink: (address?: string | Address) =>
    `${EXPLORER_BASE_URL}/address/${address}`,
};
