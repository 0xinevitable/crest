import { useReadContract } from 'wagmi';
import { formatUnits } from 'viem';

import { Contracts, CrestAccountantAbi, CrestManagerAbi } from '@/utils/contracts';

export interface BalanceData {
  title: string;
  subtitle: string;
  value: number;
  color: string;
  [key: string]: string | number;
}

export const useBalanceSheet = () => {
  // Get total assets from Accountant
  const { data: totalAssets } = useReadContract({
    address: Contracts.Crest.Accountant,
    abi: CrestAccountantAbi,
    functionName: 'getTotalAssets',
  });

  // Get positions from Manager
  const { data: positions } = useReadContract({
    address: Contracts.Crest.Manager,
    abi: CrestManagerAbi,
    functionName: 'getPositions',
  });

  // Get Core position value
  const { data: corePositionValue } = useReadContract({
    address: Contracts.Crest.Manager,
    abi: CrestManagerAbi,
    functionName: 'estimatePositionValue',
  });

  // Calculate balance sheet data
  const balanceData: BalanceData[] = [];
  const totalAssetsFormatted = totalAssets && typeof totalAssets === 'bigint' 
    ? Number(formatUnits(totalAssets, 6)) 
    : 0;
  const coreValueFormatted = corePositionValue && typeof corePositionValue === 'bigint'
    ? Number(formatUnits(corePositionValue, 6)) 
    : 0;

  if (positions && Array.isArray(positions) && totalAssetsFormatted > 0) {
    const [spotPosition, perpPosition] = positions;

    // Calculate spot position value (approximate)
    const spotSizeFormatted = spotPosition.size ? Number(formatUnits(BigInt(spotPosition.size), 8)) : 0;
    const spotEntryPrice = spotPosition.entryPrice ? Number(formatUnits(BigInt(spotPosition.entryPrice), 8)) : 0;
    const spotValue = spotSizeFormatted * spotEntryPrice;
    const spotPercentage = totalAssetsFormatted > 0 ? (spotValue / totalAssetsFormatted) * 100 : 0;

    // Calculate perp position value (approximate)
    const perpSizeFormatted = perpPosition.size ? Number(formatUnits(BigInt(perpPosition.size), 8)) : 0;
    const perpEntryPrice = perpPosition.entryPrice ? Number(formatUnits(BigInt(perpPosition.entryPrice), 8)) : 0;
    const perpValue = perpSizeFormatted * perpEntryPrice;
    const perpPercentage = totalAssetsFormatted > 0 ? (perpValue / totalAssetsFormatted) * 100 : 0;

    // Remaining USDC (vault balance + other assets)
    const remainingValue = totalAssetsFormatted - spotValue - Math.abs(perpValue);
    const remainingPercentage = totalAssetsFormatted > 0 ? (remainingValue / totalAssetsFormatted) * 100 : 0;

    // Add positions to balance data
    if (spotPosition.size > 0) {
      balanceData.push({
        title: `SPOT ${spotPosition.isLong ? 'LONG' : 'SHORT'}`,
        subtitle: 'Hyperliquid Core',
        value: Math.max(0, spotPercentage),
        color: spotPosition.isLong ? '#18edeb' : '#e24e76',
      });
    }

    if (perpPosition.size > 0) {
      balanceData.push({
        title: `PERP ${perpPosition.isLong ? 'LONG' : 'SHORT'}`,
        subtitle: 'Hyperliquid Core',
        value: Math.max(0, perpPercentage),
        color: perpPosition.isLong ? '#18edeb' : '#e24e76',
      });
    }

    // Add remaining USDC
    if (remainingValue > 0) {
      balanceData.push({
        title: 'USDC (AVAILABLE)',
        subtitle: 'Vault Balance',
        value: Math.max(0, remainingPercentage),
        color: '#0085ff',
      });
    }

    // Add allocation buffer if needed
    const totalPercentage = balanceData.reduce((sum, item) => sum + item.value, 0);
    if (totalPercentage < 100) {
      balanceData.push({
        title: 'USDC (TO BE ALLOCATED)',
        subtitle: 'Vault Reserve',
        value: Math.max(0, 100 - totalPercentage),
        color: '#7f99ff',
      });
    }
  }

  // Fallback to static data if no positions or data
  if (balanceData.length === 0) {
    balanceData.push(
      {
        title: 'USDC (AVAILABLE)',
        subtitle: 'Vault Balance',
        value: 98.85,
        color: '#0085ff',
      },
      {
        title: 'USDC (TO BE ALLOCATED)',
        subtitle: 'Vault Reserve',
        value: 1.15,
        color: '#7f99ff',
      }
    );
  }

  return {
    balanceData,
    totalAssets: totalAssetsFormatted,
    corePositionValue: coreValueFormatted,
    positions,
  };
};