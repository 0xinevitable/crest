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

import { hyperliquidEvmMainnet } from '../constants/chain';
import { crestTellerAbi, crestVaultAbi } from '../generated';

const contracts = {
  blockNumber: 14501677,
  chainId: 999,
  curator: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
  deployer: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
  diamond: '0x1A56836057e5c788C6d104f422Dc40100992EA0c',
  feeRecipient: '0x02fD526263E6D3843fdefD945511aA83c78CcF35',
  timestamp: 1758516666,
  usdt0: '0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb',
} as const;

const main = async () => {
  dotenv.config({ quiet: true });

  const privateKeyHex = process.env.PRIVATE_KEY! as Hex;
  const publicClient = createPublicClient({
    chain: hyperliquidEvmMainnet,
    transport: http(),
  });
  const walletClient = createWalletClient({
    chain: hyperliquidEvmMainnet,
    transport: http(),
    account: privateKeyToAccount(privateKeyHex),
  });
  if (walletClient.account.address !== contracts.deployer) {
    throw new Error('Wallet account is not the deployer');
  }

  // const hyperdriveMarket = await publicClient.readContract({
  //   address: contracts.diamond,
  //   abi: crestVaultAbi,
  //   functionName: 'hyperdriveMarket',
  // });
  // console.log({ hyperdriveMarket });
  // return;

  // {
  //   const hash = await walletClient.writeContract({
  //     address: contracts.diamond,
  //     abi: crestVaultAbi,
  //     functionName: 'setHyperdriveMarket',
  //     args: ['0x260F5f56aD7D14789D43Fd538429d42Ff5b82B56'],
  //   });
  //   console.log({ hash });
  //   await publicClient.waitForTransactionReceipt({ hash });
  //   console.log('Hyperdrive market set');
  // }

  const depositAmount = parseUnits('1', 6);
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
    args: [walletClient.account.address, contracts.diamond],
  });
  console.log({ usdt0Allowance });

  if (usdt0Allowance < depositAmount) {
    // approve to teller
    const hash = await walletClient.writeContract({
      address: contracts.usdt0,
      abi: erc20Abi,
      functionName: 'approve',
      args: [contracts.diamond, depositAmount],
    });
    await publicClient.waitForTransactionReceipt({ hash });

    // post allowance
    const usdt0Allowance = await publicClient.readContract({
      address: contracts.usdt0,
      abi: erc20Abi,
      functionName: 'allowance',
      args: [walletClient.account.address, contracts.diamond],
    });
    console.log({ usdt0Allowance });
  }

  const receiver = walletClient.account.address;
  // deposit to teller
  {
    const hash = await walletClient.writeContract({
      address: contracts.diamond,
      abi: crestTellerAbi,
      functionName: 'deposit',
      args: [depositAmount, receiver],
    });
    console.log({ hash });
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log(receipt);
  }

  const shares = await publicClient.readContract({
    address: contracts.diamond,
    abi: crestVaultAbi,
    functionName: 'balanceOf',
    args: [receiver],
  });
  console.log({ shares });
};

main();

export {};
