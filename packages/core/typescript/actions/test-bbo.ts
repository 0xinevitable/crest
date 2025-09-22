// Foundry (forge) does not support precompiles, even with `forge script --skip-simulation` (https://github.com/foundry-rs/foundry/issues/6825)
// Therefore we use `viem` for testing
import * as dotenv from 'dotenv';
import {
  Address,
  Hex,
  createPublicClient,
  createWalletClient,
  decodeFunctionResult,
  hexToBigInt,
  http,
  padHex,
  toHex,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

import _contracts from '../../deployments/998.json';
import { hyperliquidEvmTestnet } from '../constants/chain';

const contracts = _contracts as Record<keyof typeof _contracts, Address>;

const main = async () => {
  dotenv.config({ quiet: true });

  const privateKeyHex = process.env.PRIVATE_KEY! as Hex;
  const publicClient = createPublicClient({
    chain: hyperliquidEvmTestnet,
    transport: http(),
  });
  const walletClient = createWalletClient({
    chain: hyperliquidEvmTestnet,
    transport: http(),
    account: privateKeyToAccount(privateKeyHex),
  });
  if (walletClient.account.address !== contracts.deployer) {
    throw new Error('Wallet account is not the deployer');
  }

  const bbo = async (symbol: string, assetIndex: number) => {
    const data = padHex(toHex(assetIndex), { size: 32 });
    console.log({ assetIndex, data });
    const { data: bbo } = await publicClient.call({
      to: '0x000000000000000000000000000000000000080e',
      account: walletClient.account,
      data,
    });

    const raw = (bbo || '').replace('0x', '');
    const [bid, ask] = [
      hexToBigInt(`0x${raw.slice(0, 64)}`),
      hexToBigInt(`0x${raw.slice(64, 128)}`),
    ];
    console.log({ symbol, assetIndex, bid, ask });
  };

  const HYPE = {
    symbol: 'HYPE',
    tokenIndex: 1105,
    spotIndex: 1035,
    perpIndex: 135,
  };
  await bbo('HYPE', HYPE.spotIndex + 10000);
  // { symbol: 'HYPE', assetIndex: 11035, bid: 41000000n, ask: 90510000n }
  await bbo('HYPE-USD', HYPE.perpIndex);
  // { symbol: 'HYPE-USD', assetIndex: 135, bid: 645860n, ask: 905270n }

  const USDT0 = {
    symbol: 'TZERO',
    tokenIndex: 1204,
    spotIndex: 1115,
    perpIndex: -1,
  };
  await bbo('USDT0', USDT0.spotIndex + 10000);
  // { symbol: 'USDT0', assetIndex: 11115, bid: 6925n, ask: 6946n }
};

main();

export {};
