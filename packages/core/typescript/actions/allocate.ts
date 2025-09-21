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
  parseEventLogs,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { hyperliquidEvmTestnet } from 'viem/chains';

import _contracts from '../../deployments/998.json';
import { crestManagerAbi, crestVaultAbi } from '../generated';

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

  // ===== ALLOCATE =====

  const market = {
    symbol: 'HYPE',
    tokenIndex: 1105,
    spotIndex: 1035,
    perpIndex: 135,
  };

  // allocate to market
  {
    const hash = await walletClient.writeContract({
      address: contracts.manager,
      abi: crestManagerAbi,
      functionName: 'allocate',
      args: [market.spotIndex, market.perpIndex],
    });
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log(receipt);

    const logs = parseEventLogs({
      logs: receipt.logs,
      abi: [...crestManagerAbi, ...crestVaultAbi, ...erc20Abi],
    });

    for (const log of logs) {
      console.log(log);
    }
  }
};

main();

export {};
