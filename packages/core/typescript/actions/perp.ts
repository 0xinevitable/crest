// Foundry (forge) does not support precompiles, even with `forge script --skip-simulation` (https://github.com/foundry-rs/foundry/issues/6825)
// Therefore we use `viem` for testing
import * as dotenv from 'dotenv';
import {
  Address,
  Hex,
  createPublicClient,
  createWalletClient,
  encodeFunctionData,
  encodePacked,
  erc20Abi,
  http,
  parseAbi,
  parseAbiItem,
  parseUnits,
} from 'viem';
import { sendCalls } from 'viem/_types/actions/wallet/sendCalls';
import { privateKeyToAccount } from 'viem/accounts';

import { hyperliquidEvmMainnet } from '../constants/chain';

const managerFacetAbi = parseAbi([
  'function manage(address target, bytes calldata data, uint256 value) external returns (bytes memory result)',
  'function placeLimitOrder(uint32 asset, bool isBuy, uint64 limitPx, uint64 sz, bool reduceOnly, uint8 encodedTif, uint128 cloid) external',
]);

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

  // move spot usdc to perp
  {
    const USD_CLASS_TRANSFER_ACTION = 7;
    const target = '0x3333333333333333333333333333333333333333';
    const data = encodeFunctionData({
      abi: [
        parseAbiItem('function sendRawAction(bytes calldata data) external'),
      ],
      functionName: 'sendRawAction',
      args: [
        // abi.encodePacked(
        //   uint8(1),
        //   HLConstants.USD_CLASS_TRANSFER_ACTION,
        //   abi.encode(ntl, toPerp),
        // ),

        encodePacked(
          ['uint8', 'uint24', 'bytes'],
          [
            1,
            USD_CLASS_TRANSFER_ACTION,
            encodePacked(['uint64', 'bool'], [parseUnits('4', 8), true]),
          ],
        ),
      ],
    });

    const hash = await walletClient.writeContract({
      address: contracts.diamond,
      abi: managerFacetAbi,
      functionName: 'manage',
      args: [target, data, 0n],
    });
    console.log({ hash });

    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log(receipt);
  }

  const ASTER_perpIndex = 207;
  const TIF = 1; // IOC

  const hash = await walletClient.writeContract({
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
      false, // sell (SHORT)
      parseUnits('1.3724', 8), // limitPx,
      parseUnits('10', 8), // size,
      false, // reduceOnly
      TIF,
      1n,
    ],
  });
  console.log({ hash });

  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log(receipt);
};

main();

export {};
