import { useMemo } from 'react';
import { usePublicClient } from 'wagmi';
import { formatUnits } from 'viem';

import { Contracts, CrestTellerAbi, CrestVaultAbi, CrestManagerAbi } from '@/utils/contracts';

export interface OperationItem {
  type: 'ALLOCATION' | 'REBALANCING' | 'DEPOSIT' | 'WITHDRAW';
  label: string;
  timestamp: string;
  txId: string;
  icon?: string;
}

export const useOperationHistory = () => {
  const publicClient = usePublicClient();

  // For now, we'll use a simplified version that fetches recent events
  // In a production app, you'd want to use useBlockNumber and getLogs with proper pagination
  
  const mockOperations: OperationItem[] = useMemo(() => {
    // This would be replaced with actual event fetching logic
    // Example implementation:
    /*
    const fetchEvents = async () => {
      if (!publicClient) return [];

      const currentBlock = await publicClient.getBlockNumber();
      const fromBlock = currentBlock - 10000n; // Last ~10k blocks

      // Fetch Deposit events
      const depositLogs = await publicClient.getLogs({
        address: Contracts.Crest.Teller,
        event: {
          type: 'event',
          name: 'Deposit',
          inputs: [
            { type: 'address', name: 'user', indexed: true },
            { type: 'uint256', name: 'assets' },
            { type: 'uint256', name: 'shares' }
          ]
        },
        fromBlock,
        toBlock: currentBlock,
      });

      // Fetch Withdraw events
      const withdrawLogs = await publicClient.getLogs({
        address: Contracts.Crest.Teller,
        event: {
          type: 'event',
          name: 'Withdraw',
          inputs: [
            { type: 'address', name: 'user', indexed: true },
            { type: 'uint256', name: 'assets' },
            { type: 'uint256', name: 'shares' }
          ]
        },
        fromBlock,
        toBlock: currentBlock,
      });

      // Fetch Allocation events
      const allocationLogs = await publicClient.getLogs({
        address: Contracts.Crest.Vault,
        event: {
          type: 'event',
          name: 'Allocation',
          inputs: [
            { type: 'uint32', name: 'spotIndex' },
            { type: 'uint32', name: 'perpIndex' },
            { type: 'uint256', name: 'amount' }
          ]
        },
        fromBlock,
        toBlock: currentBlock,
      });

      // Fetch Rebalance events
      const rebalanceLogs = await publicClient.getLogs({
        address: Contracts.Crest.Manager,
        event: {
          type: 'event',
          name: 'Rebalanced',
          inputs: [
            { type: 'uint32', name: 'oldSpotIndex' },
            { type: 'uint32', name: 'oldPerpIndex' },
            { type: 'uint32', name: 'newSpotIndex' },
            { type: 'uint32', name: 'newPerpIndex' }
          ]
        },
        fromBlock,
        toBlock: currentBlock,
      });

      // Process and format events
      const operations: OperationItem[] = [];

      // Process deposits
      depositLogs.forEach(log => {
        const assets = log.args?.assets;
        if (assets) {
          operations.push({
            type: 'DEPOSIT',
            label: `+${Number(formatUnits(assets, 6)).toFixed(0)} USDC`,
            timestamp: formatTimestamp(log.blockNumber),
            txId: log.transactionHash,
          });
        }
      });

      // Process withdrawals
      withdrawLogs.forEach(log => {
        const assets = log.args?.assets;
        if (assets) {
          operations.push({
            type: 'WITHDRAW',
            label: `-${Number(formatUnits(assets, 6)).toFixed(0)} USDC`,
            timestamp: formatTimestamp(log.blockNumber),
            txId: log.transactionHash,
          });
        }
      });

      // Process allocations
      allocationLogs.forEach(log => {
        const amount = log.args?.amount;
        if (amount) {
          operations.push({
            type: 'ALLOCATION',
            label: `+${Number(formatUnits(amount, 6)).toFixed(0)} USDC`,
            timestamp: formatTimestamp(log.blockNumber),
            txId: log.transactionHash,
          });
        }
      });

      // Process rebalances
      rebalanceLogs.forEach(log => {
        operations.push({
          type: 'REBALANCING',
          label: 'Position Rebalanced',
          timestamp: formatTimestamp(log.blockNumber),
          txId: log.transactionHash,
        });
      });

      // Sort by block number (most recent first)
      return operations.sort((a, b) => {
        // This would need proper timestamp comparison
        return b.txId.localeCompare(a.txId);
      });
    };
    */

    // For now, return enhanced mock data that looks more realistic
    return [
      {
        type: 'ALLOCATION',
        label: '+1,334 USDC',
        timestamp: '2h ago',
        txId: '0x1234...5678',
      },
      {
        type: 'REBALANCING',
        label: 'HYPE/USDC Rebalanced',
        timestamp: '4h ago',
        txId: '0x2345...6789',
      },
      {
        type: 'DEPOSIT',
        label: '+500 USDC',
        timestamp: '6h ago',
        txId: '0x3456...7890',
      },
      {
        type: 'REBALANCING',
        label: 'Position Adjusted',
        timestamp: '8h ago',
        txId: '0x4567...8901',
      },
      {
        type: 'ALLOCATION',
        label: '+2,150 USDC',
        timestamp: '12h ago',
        txId: '0x5678...9012',
      },
      {
        type: 'WITHDRAW',
        label: '-100 USDC',
        timestamp: '1d ago',
        txId: '0x6789...0123',
      },
    ];
  }, [publicClient]);

  // Helper function to format block number to relative time
  const formatTimestamp = (blockNumber: bigint): string => {
    // This would calculate actual time difference based on block timestamp
    // For now, return relative time format
    return `${blockNumber}h ago`;
  };

  return {
    operations: mockOperations,
    isLoading: false, // Would be true while fetching events
    refetch: () => {
      // Would refetch events
      console.log('Refetching operation history...');
    },
  };
};