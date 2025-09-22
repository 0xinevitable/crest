import { waitForTransactionReceipt } from '@wagmi/core';
import { Hash, TransactionReceipt } from 'viem';

import { wagmiConfig } from '@/constants/config';

import { toastTransaction } from './toast';

export const finalizedTX = async (promise: Promise<Hash>) => {
  return await toastTransaction(
    new Promise<TransactionReceipt>(async (resolve, reject) => {
      try {
        const hash = await promise;
        console.log(`[*] Submitted tx: ${hash}`);
        if (!hash) {
          reject(new Error('No hash returned'));
          return;
        }
        const receipt = await waitForTransactionReceipt(wagmiConfig, {
          hash: hash,
        });
        console.log(`[*] Tx receipt for ${hash}:`, receipt);
        resolve(receipt);
      } catch (error) {
        console.log(`[!] Error waiting for tx receipt: ${error}`);
        reject(error);
      }
    }),
  );
};
