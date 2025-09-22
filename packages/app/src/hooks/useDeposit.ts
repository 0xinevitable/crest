import { useCallback, useEffect, useMemo, useState } from 'react';
import { toast } from 'react-toastify';
import { erc20Abi, formatUnits, maxInt256, parseUnits } from 'viem';
import {
  useAccount,
  useBalance,
  useReadContract,
  useWriteContract,
} from 'wagmi';

import { Contracts, CrestTellerAbi } from '@/utils/contracts';
import { finalizedTX } from '@/utils/finalize';

export type DepositStatus =
  | 'idle'
  | 'calculating'
  | 'checkingApproval'
  | 'needsApproval'
  | 'approving'
  | 'depositing'
  | 'success'
  | 'error';

export const useDeposit = (amount: string) => {
  const { address } = useAccount();
  const [status, setStatus] = useState<DepositStatus>('idle');
  const [txHash, setTxHash] = useState<string | null>(null);

  const parsedAmount = useMemo(() => {
    try {
      return amount && Number(amount) > 0 ? parseUnits(amount, 6) : BigInt(0);
    } catch {
      return BigInt(0);
    }
  }, [amount]);

  const { data: balance, refetch: refetchBalance } = useBalance({
    address,
    token: Contracts.Tokens.USDT0,
  });

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: Contracts.Tokens.USDT0,
    abi: erc20Abi,
    functionName: 'allowance',
    args: address ? [address, Contracts.Crest.Teller] : undefined,
    query: {
      enabled: !!address,
    },
  });

  const { data: shares, isLoading: isCalculatingShares } = useReadContract({
    address: Contracts.Crest.Teller,
    abi: CrestTellerAbi,
    functionName: 'previewDeposit',
    args: [parsedAmount],
    query: {
      enabled: parsedAmount > BigInt(0),
    },
  });

  console.log({ allowance, parsedAmount });

  // Calculate needsApproval before using it in gas estimation
  const needsApproval = useMemo(() => {
    if (typeof allowance === 'undefined' || parsedAmount === BigInt(0))
      return false;
    return allowance < parsedAmount;
  }, [allowance, parsedAmount]);

  const {
    writeContractAsync,
    isPending: isWritePending,
    reset: resetWriteContract,
  } = useWriteContract();

  const handleSubmit = useCallback(async () => {
    if (parsedAmount === BigInt(0) || !address) return;

    // Validate minimum deposit (1 USDT0)
    const MIN_DEPOSIT = parseUnits('1', 6);
    if (parsedAmount < MIN_DEPOSIT) {
      toast.error('Minimum deposit is 1 USDT0');
      return;
    }

    // Check if user has sufficient balance
    if (balance && parsedAmount > balance.value) {
      toast.error('Insufficient USDT0 balance');
      return;
    }

    setTxHash(null);

    try {
      if (needsApproval) {
        setStatus('approving');
        const promise = writeContractAsync({
          address: Contracts.Tokens.USDT0,
          abi: erc20Abi,
          functionName: 'approve',
          args: [Contracts.Crest.Teller, maxInt256],
        });
        await finalizedTX(promise, setTxHash);
        refetchAllowance();
        setStatus('idle');
      } else {
        setStatus('depositing');
        const promise = writeContractAsync({
          address: Contracts.Crest.Teller,
          abi: CrestTellerAbi,
          functionName: 'deposit',
          args: [parsedAmount, address],
        });
        await finalizedTX(promise, setTxHash);
        refetchBalance();
        setStatus('success');
      }
    } catch (e: unknown) {
      console.error('Transaction error:', e);
      setStatus('error');
      resetWriteContract();
    }
  }, [
    needsApproval,
    parsedAmount,
    address,
    writeContractAsync,
    resetWriteContract,
    balance,
  ]);

  const isLoading = isWritePending;
  const sharesFormatted = shares ? formatUnits(shares as bigint, 6) : '0';

  return {
    status,
    isLoading,
    isCalculatingShares,
    needsApproval,
    balance,
    shares: sharesFormatted,
    txHash,
    submit: handleSubmit,
    reset: () => {
      setStatus('idle');
      setTxHash(null);
      resetWriteContract();
    },
  };
};
