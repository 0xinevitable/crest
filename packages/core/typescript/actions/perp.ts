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
import { sendCalls } from 'viem/_types/actions/wallet/sendCalls';
import { privateKeyToAccount } from 'viem/accounts';

import { hyperliquidEvmMainnet } from '../constants/chain';
import { managerFacetAbi } from '../generated';

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

  const ASTER_perpIndex = 207n;
  const limitPx = '';
  const size = '';
  const TIF = 3; // IOC

  await walletClient.writeContract({
    address: contracts.diamond,
    abi: managerFacetAbi,
    functionName: 'placeLimitOrder',
    args: [
      //   CoreWriterLib.placeLimitOrder(
      //     asset,
      //     isBuy,
      //     limitPx,
      //     sz,
      //     reduceOnly,
      //     encodedTif,
      //     cloid
      // );
      ASTER_perpIndex,
      false, // sell
      limitPx,
      size,
      false, // reduceOnly
      TIF,
      1,
    ],
  });
};

main();

export {};
