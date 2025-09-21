// Foundry (forge) does not support precompiles, even with `forge script --skip-simulation` (https://github.com/foundry-rs/foundry/issues/6825)
// Therefore we use `viem` for testing
import * as dotenv from 'dotenv';
import {
  Address,
  Hex,
  createPublicClient,
  createWalletClient,
  erc20Abi,
  http,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

import _contracts from '../../deployments/998.json';
import { hyperliquidEvmTestnet } from '../constants/chain';
import {
  crestManagerAbi,
  crestVaultAbi,
  hypeTradingContractAbi,
} from '../generated';

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

  const [spotPos, perpPos] = await publicClient.readContract({
    address: contracts.manager,
    abi: crestManagerAbi,
    functionName: 'getPositions',
  });
  console.log({
    spotPos: {
      index: spotPos.index,
      isLong: spotPos.isLong,
      size: spotPos.size,
      entryPrice: spotPos.entryPrice,
      timestamp: spotPos.timestamp,
    },
    perpPos: {
      index: perpPos.index,
      isLong: perpPos.isLong,
      size: perpPos.size,
      entryPrice: perpPos.entryPrice,
      timestamp: perpPos.timestamp,
    },
  });

  // ON MAINNET, IDLE IS 0 (BECAUSE ITS PARKED ON HYPERDRIVE)
  const ldleUsdt0Balance = await publicClient.readContract({
    address: contracts.usdt0,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: [contracts.vault],
  });
  console.log({ ldleUsdt0Balance });

  const totalAllocated = await publicClient.readContract({
    address: contracts.manager,
    abi: crestManagerAbi,
    functionName: 'totalAllocated',
  });
  console.log({ totalAllocated });

  const positionValue = await publicClient.readContract({
    address: contracts.manager,
    abi: crestManagerAbi,
    functionName: 'estimatePositionValue',
  });
  console.log({ positionValue });

  const hyperdriveValue = await publicClient.readContract({
    address: contracts.vault,
    abi: crestVaultAbi,
    functionName: 'getHyperdriveValue',
  });
  console.log({ hyperdriveValue });

  const hypeTradingContractAddress =
    '0x0FA2b5d19d6BF4FC87a83E0B268F0357dbB4be07';

  const pos1 = await publicClient.readContract({
    address: hypeTradingContractAddress,
    abi: hypeTradingContractAbi,
    functionName: 'getUserPosition',
    args: [contracts.manager, 135],
  });
  console.log(pos1);
};

main();

export {};
