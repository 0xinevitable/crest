// Foundry (forge) does not support precompiles, even with `forge script --skip-simulation` (https://github.com/foundry-rs/foundry/issues/6825)
// Therefore we use `viem` for testing
import * as dotenv from 'dotenv';
import {
  Address,
  Hex,
  createPublicClient,
  createWalletClient,
  http,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { hyperliquidEvmTestnet } from 'viem/chains';

import _contracts from '../../deployments/998.json';

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

  {
    // fix nonce
    const hash = await walletClient.sendTransaction({
      address: walletClient.account.address,
      value: 0n,
      nonce: await publicClient.getTransactionCount({
        address: walletClient.account.address,
      }),
      gas: 1000000n,
    });
    console.log({ hash });
    await publicClient.waitForTransactionReceipt({ hash });
  }
};

main();

export {};
