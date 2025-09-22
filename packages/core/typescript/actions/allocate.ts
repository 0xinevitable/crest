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
  parseUnits,
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

  // {
  //   // fix nonce
  //   const hash = await walletClient.sendTransaction({
  //     address: walletClient.account.address,
  //     value: 0n,
  //     nonce: await publicClient.getTransactionCount({
  //       address: walletClient.account.address,
  //     }),
  //     gas: 1000000n,
  //   });
  //   console.log({ hash });
  //   await publicClient.waitForTransactionReceipt({ hash });
  // }

  // transfer 22 USDT0 to vault
  // {
  //   const hash = await walletClient.writeContract({
  //     address: contracts.usdt0,
  //     abi: erc20Abi,
  //     functionName: 'transfer',
  //     args: [contracts.vault, parseUnits('4', 18)],
  //   });
  //   console.log({ hash });
  //   await publicClient.waitForTransactionReceipt({ hash });
  // }

  // log usdt0 balance of vault and sender
  {
    const usdt0Balance = await publicClient.readContract({
      address: contracts.usdt0,
      abi: erc20Abi,
      functionName: 'balanceOf',
      args: [contracts.vault],
    });
    console.log('VAULT', { usdt0Balance });
  }

  {
    const usdt0Balance = await publicClient.readContract({
      address: contracts.usdt0,
      abi: erc20Abi,
      functionName: 'balanceOf',
      args: [walletClient.account.address],
    });
    console.log('SENDER', { usdt0Balance });
  }

  // allocate to market
  // {
  //   const hash = await walletClient.writeContract({
  //     address: contracts.manager,
  //     abi: crestManagerAbi,
  //     functionName: 'allocate__bridgeToCore',
  //     args: [],
  //   });
  //   const receipt = await publicClient.waitForTransactionReceipt({ hash });
  //   console.log(receipt);

  //   const logs = parseEventLogs({
  //     logs: receipt.logs,
  //     abi: [...crestManagerAbi, ...crestVaultAbi, ...erc20Abi],
  //   });

  //   for (const log of logs) {
  //     console.log(log);
  //   }
  // }

  {
    const hash = await walletClient.writeContract({
      address: contracts.manager,
      abi: crestManagerAbi,
      functionName: 'allocate__swapToUSDC',
      args: [],
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
