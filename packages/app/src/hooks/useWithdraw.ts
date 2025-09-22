import { useCallback, useMemo, useState } from 'react';
import { toast } from 'react-toastify';
import { erc20Abi, formatUnits, parseUnits } from 'viem';
import {
  useAccount,
  useBalance,
  useReadContract,
  useWriteContract,
} from 'wagmi';

import { Contracts, CrestTellerAbi } from '@/utils/contracts';
import { finalizedTX } from '@/utils/finalize';

export type WithdrawStatus =
  | 'idle'
  | 'calculating'
  | 'withdrawing'
  | 'success'
  | 'error';

export const useWithdraw = (amount: string) => {
  const { address } = useAccount();
  const [status, setStatus] = useState<WithdrawStatus>('idle');
  const [txHash, setTxHash] = useState<string | null>(null);

  const parsedAmount = useMemo(() => {
    try {
      return amount && Number(amount) > 0 ? parseUnits(amount, 6) : BigInt(0);
    } catch {
      return BigInt(0);
    }
  }, [amount]);

  // Get CREST balance (shares)
  const { data: balance, refetch: refetchBalance } = useBalance({
    address,
    token: Contracts.Crest.Vault,
  });

  // Preview how much USDT0 user will receive
  const { data: assets, isLoading: isCalculatingAssets } = useReadContract({
    address: Contracts.Crest.Teller,
    abi: CrestTellerAbi,
    functionName: 'previewRedeem',
    args: [parsedAmount],
    query: {
      enabled: parsedAmount > BigInt(0),
    },
  });

  const {
    writeContractAsync,
    isPending: isWritePending,
    reset: resetWriteContract,
  } = useWriteContract();

  const handleSubmit = useCallback(async () => {
    if (parsedAmount === BigInt(0) || !address) return;

    // Validate minimum withdraw (0.000001 CREST)
    const MIN_WITHDRAW = parseUnits('0.000001', 6);
    if (parsedAmount < MIN_WITHDRAW) {
      toast.error('Minimum withdrawal is 0.000001 CREST');
      return;
    }

    // Check if user has sufficient balance
    if (balance && parsedAmount > balance.value) {
      toast.error('Insufficient CREST balance');
      return;
    }

    setTxHash(null);

    try {
      setStatus('withdrawing');
      const promise = writeContractAsync({
        address: Contracts.Crest.Teller,
        abi: CrestTellerAbi,
        functionName: 'redeem',
        args: [parsedAmount, address, address],
      });
      await finalizedTX(promise, setTxHash);
      refetchBalance();
      setStatus('success');
    } catch (e: unknown) {
      console.error('Withdrawal error:', e);
      setStatus('error');
      resetWriteContract();
    }
  }, [
    parsedAmount,
    address,
    writeContractAsync,
    resetWriteContract,
    balance,
  ]);

  const isLoading = isWritePending;
  const assetsFormatted = assets ? formatUnits(assets as bigint, 6) : '0';

  return {
    status,
    isLoading,
    isCalculatingAssets,
    balance,
    assets: assetsFormatted,
    txHash,
    submit: handleSubmit,
    reset: () => {
      setStatus('idle');
      setTxHash(null);
      resetWriteContract();
    },
  };
};