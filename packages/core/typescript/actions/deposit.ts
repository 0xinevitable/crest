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
  parseUnits,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

import _contracts from '../../deployments/998.json';
import { hyperliquidEvmTestnet } from '../constants/chain';
import { crestTellerAbi, crestVaultAbi } from '../generated';

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

  const depositAmount = parseUnits('22', 6);
  console.log({ depositAmount });

  const usdt0Balance = await publicClient.readContract({
    address: contracts.usdt0,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: [walletClient.account.address],
  });
  console.log({ usdt0Balance });
  if (usdt0Balance === 0n || usdt0Balance < depositAmount) {
    throw new Error('Insufficient balance');
  }

  const usdt0Allowance = await publicClient.readContract({
    address: contracts.usdt0,
    abi: erc20Abi,
    functionName: 'allowance',
    args: [walletClient.account.address, contracts.teller],
  });
  console.log({ usdt0Allowance });

  if (usdt0Allowance < depositAmount) {
    // approve to teller
    const hash = await walletClient.writeContract({
      address: contracts.usdt0,
      abi: erc20Abi,
      functionName: 'approve',
      args: [contracts.teller, depositAmount],
    });
    await publicClient.waitForTransactionReceipt({ hash });

    // post allowance
    const usdt0Allowance = await publicClient.readContract({
      address: contracts.usdt0,
      abi: erc20Abi,
      functionName: 'allowance',
      args: [walletClient.account.address, contracts.teller],
    });
    console.log({ usdt0Allowance });
  }

  const receiver = walletClient.account.address;
  // deposit to teller
  {
    const hash = await walletClient.writeContract({
      address: contracts.teller,
      abi: crestTellerAbi,
      functionName: 'deposit',
      args: [depositAmount, receiver],
    });
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log(receipt);
  }

  const shares = await publicClient.readContract({
    address: contracts.vault,
    abi: crestVaultAbi,
    functionName: 'balanceOf',
    args: [receiver],
  });
  console.log({ shares });
};

main();

export {};
