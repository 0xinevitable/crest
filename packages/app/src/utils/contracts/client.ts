import { readContract } from '@wagmi/core';
import { Address, ContractFunctionParameters } from 'viem';

import { wagmiConfig } from '@/constants/config';

import {
  CrestAccountantAbi,
  CrestManagerAbi,
  CrestTellerAbi,
  CrestVaultAbi,
} from './abis';
import { Contracts } from './addresses';

export interface Position {
  index: number;
  isLong: boolean;
  size: bigint;
  entryPrice: bigint;
  timestamp: bigint;
}

export class CrestClient {
  private async readContract(config: ContractFunctionParameters) {
    return readContract(wagmiConfig, config);
  }

  // ==================== TELLER QUERIES ====================

  async previewDeposit(assets: bigint): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Teller,
      abi: CrestTellerAbi,
      functionName: 'previewDeposit',
      args: [assets],
    }) as Promise<bigint>;
  }

  async previewWithdraw(shares: bigint): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Teller,
      abi: CrestTellerAbi,
      functionName: 'previewWithdraw',
      args: [shares],
    }) as Promise<bigint>;
  }

  async areSharesLocked(user: Address): Promise<boolean> {
    return this.readContract({
      address: Contracts.Crest.Teller,
      abi: CrestTellerAbi,
      functionName: 'areSharesLocked',
      args: [user],
    }) as Promise<boolean>;
  }

  async getShareUnlockTime(user: Address): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Teller,
      abi: CrestTellerAbi,
      functionName: 'getShareUnlockTime',
      args: [user],
    }) as Promise<bigint>;
  }

  // ==================== ACCOUNTANT QUERIES ====================

  async convertToShares(assets: bigint): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Accountant,
      abi: CrestAccountantAbi,
      functionName: 'convertToShares',
      args: [assets],
    }) as Promise<bigint>;
  }

  async convertToAssets(shares: bigint): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Accountant,
      abi: CrestAccountantAbi,
      functionName: 'convertToAssets',
      args: [shares],
    }) as Promise<bigint>;
  }

  async getExchangeRate(): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Accountant,
      abi: CrestAccountantAbi,
      functionName: 'getRate',
    }) as Promise<bigint>;
  }

  async canUpdateRate(): Promise<boolean> {
    return this.readContract({
      address: Contracts.Crest.Accountant,
      abi: CrestAccountantAbi,
      functionName: 'canUpdateRate',
    }) as Promise<boolean>;
  }

  async timeUntilNextUpdate(): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Accountant,
      abi: CrestAccountantAbi,
      functionName: 'timeUntilNextUpdate',
    }) as Promise<bigint>;
  }

  // ==================== VAULT QUERIES ====================

  async getTotalSupply(): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Vault,
      abi: CrestVaultAbi,
      functionName: 'totalSupply',
    }) as Promise<bigint>;
  }

  async getBalanceOf(account: Address): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Vault,
      abi: CrestVaultAbi,
      functionName: 'balanceOf',
      args: [account],
    }) as Promise<bigint>;
  }

  // ==================== MANAGER QUERIES ====================

  async getPositions(): Promise<{ spot: Position; perp: Position }> {
    const result = (await this.readContract({
      address: Contracts.Crest.Manager,
      abi: CrestManagerAbi,
      functionName: 'getPositions',
    })) as [Position, Position];

    return {
      spot: result[0],
      perp: result[1],
    };
  }

  async hasOpenPositions(): Promise<boolean> {
    return this.readContract({
      address: Contracts.Crest.Manager,
      abi: CrestManagerAbi,
      functionName: 'hasOpenPositions',
    }) as Promise<boolean>;
  }

  async estimatePositionValue(): Promise<bigint> {
    return this.readContract({
      address: Contracts.Crest.Manager,
      abi: CrestManagerAbi,
      functionName: 'estimatePositionValue',
    }) as Promise<bigint>;
  }
}
