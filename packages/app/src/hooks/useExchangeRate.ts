import { useReadContract } from 'wagmi';
import { formatUnits } from 'viem';

import { Contracts, CrestAccountantAbi } from '@/utils/contracts';

export const useExchangeRate = () => {
  const { data: exchangeRateRaw, isLoading, error } = useReadContract({
    address: Contracts.Crest.Accountant,
    abi: CrestAccountantAbi,
    functionName: 'exchangeRate',
  });

  const exchangeRate = exchangeRateRaw 
    ? Number(formatUnits(exchangeRateRaw as bigint, 6)).toFixed(4)
    : '1.00';

  return {
    exchangeRate,
    isLoading,
    error,
  };
};