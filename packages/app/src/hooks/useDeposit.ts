import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Address,
  encodeFunctionData,
  erc20Abi,
  formatUnits,
  maxInt256,
  parseUnits,
} from 'viem';
import {
  useAccount,
  useBalance,
  useEstimateGas,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
} from 'wagmi';

import { Contracts, CrestTellerAbi } from '@/utils/contracts';

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
  const [error, setError] = useState<string | null>(null);
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

  // Calculate needsApproval before using it in gas estimation
  const needsApproval = useMemo(() => {
    if (!allowance || parsedAmount === BigInt(0)) return false;
    return allowance < parsedAmount;
  }, [allowance, parsedAmount]);

  // Gas estimation for approve transaction
  const { data: approveGasEstimate } = useEstimateGas({
    to: Contracts.Tokens.USDT0,
    data: encodeFunctionData({
      abi: erc20Abi,
      functionName: 'approve',
      args: [Contracts.Crest.Teller, maxInt256],
    }),
    query: {
      enabled: needsApproval && !!address,
    },
  });

  // Gas estimation for deposit transaction
  const { data: depositGasEstimate } = useEstimateGas({
    to: Contracts.Crest.Teller,
    data: address
      ? encodeFunctionData({
          abi: CrestTellerAbi,
          functionName: 'deposit',
          args: [parsedAmount, address],
        })
      : undefined,
    query: {
      enabled: !needsApproval && parsedAmount > BigInt(0) && !!address,
    },
  });

  const {
    writeContractAsync,
    data: writeTxHash,
    isPending: isWritePending,
    reset: resetWriteContract,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash: writeTxHash as Address | undefined,
    });

  const handleSubmit = useCallback(async () => {
    if (parsedAmount === BigInt(0) || !address) return;

    // Validate minimum deposit (1 USDT0)
    const MIN_DEPOSIT = parseUnits('1', 6);
    if (parsedAmount < MIN_DEPOSIT) {
      setError('Minimum deposit is 1 USDT0');
      return;
    }

    // Check if user has sufficient balance
    if (balance && parsedAmount > balance.value) {
      setError('Insufficient USDT0 balance');
      return;
    }

    setError(null);
    setTxHash(null);

    try {
      let hash: Address;
      if (needsApproval) {
        setStatus('approving');
        hash = await writeContractAsync({
          address: Contracts.Tokens.USDT0,
          abi: erc20Abi,
          functionName: 'approve',
          args: [Contracts.Crest.Teller, maxInt256],
        });
      } else {
        setStatus('depositing');
        hash = await writeContractAsync({
          address: Contracts.Crest.Teller,
          abi: CrestTellerAbi,
          functionName: 'deposit',
          args: [parsedAmount, address],
        });
      }
      setTxHash(hash);
    } catch (e: unknown) {
      console.error('Transaction error:', e);
      setStatus('error');

      let errorMessage = 'An unknown error occurred.';

      try {
        if (e && typeof e === 'object') {
          const error = e as Record<string, any>;
          const message =
            error.message || error.shortMessage || error.details || '';
          const causeMessage = error.cause?.message || '';
          const combinedMessage = `${message} ${causeMessage}`.toLowerCase();

          if (
            combinedMessage.includes('intrinsic gas too low') ||
            combinedMessage.includes('intrinsic gas value too low')
          ) {
            errorMessage =
              'Transaction failed: Not enough gas. The transaction requires more gas than estimated.';
          } else if (
            combinedMessage.includes('rejected') ||
            combinedMessage.includes('user rejected')
          ) {
            errorMessage = 'Transaction cancelled by user.';
          } else if (message) {
            errorMessage = message;
          }
        }
      } catch {
        // If any error occurs in parsing, use the default message
        errorMessage = 'An unexpected error occurred.';
      }

      setError(errorMessage);
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

  useEffect(() => {
    if (isConfirmed) {
      setStatus('success');
      if (status === 'approving') {
        refetchAllowance();
      }
      if (status === 'depositing') {
        refetchBalance();
      }
      resetWriteContract();
    }
  }, [
    isConfirmed,
    status,
    refetchAllowance,
    refetchBalance,
    resetWriteContract,
  ]);

  const isLoading = isWritePending || isConfirming;
  const sharesFormatted = shares ? formatUnits(shares as bigint, 6) : '0';

  return {
    status,
    isLoading,
    isCalculatingShares,
    isConfirming,
    needsApproval,
    error,
    balance,
    shares: sharesFormatted,
    txHash,
    submit: handleSubmit,
    reset: () => {
      setStatus('idle');
      setError(null);
      setTxHash(null);
      resetWriteContract();
    },
  };
};
