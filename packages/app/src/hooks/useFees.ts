import { useReadContract } from 'wagmi';

import { Contracts, CrestAccountantAbi } from '@/utils/contracts';

export const useFees = () => {
  const { data: platformFeeBps } = useReadContract({
    address: Contracts.Crest.Accountant,
    abi: CrestAccountantAbi,
    functionName: 'platformFeeBps',
  });

  const { data: performanceFeeBps } = useReadContract({
    address: Contracts.Crest.Accountant,
    abi: CrestAccountantAbi,
    functionName: 'performanceFeeBps',
  });

  // Convert basis points to percentage strings
  const platformFeePercent = platformFeeBps ? `${(Number(platformFeeBps) / 100).toFixed(1)}%` : '1%';
  const performanceFeePercent = performanceFeeBps ? `${(Number(performanceFeeBps) / 100).toFixed(1)}%` : '5%';

  const fees = [
    { 
      label: 'Performance Fee', 
      value: performanceFeePercent, 
      showInfo: true 
    },
    { 
      label: 'Management Fee', 
      value: platformFeePercent, 
      showInfo: true 
    },
    { 
      label: 'Withdrawal Period', 
      value: '1 days', 
      showInfo: false 
    },
  ];

  return {
    platformFeeBps,
    performanceFeeBps,
    platformFeePercent,
    performanceFeePercent,
    fees,
  };
};