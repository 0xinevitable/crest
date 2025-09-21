import { readContract, writeContract } from '@wagmi/core';
import { Abi, Account, Address, ContractFunctionArgs, ContractFunctionName } from 'viem';



import { wagmiConfig } from '@/constants/config';



import { CrestAccountantAbi, CrestManagerAbi, CrestTellerAbi, CrestVaultAbi } from './abis';
import { Contracts } from './addresses';


class ContractClient<TAbi extends Abi> {
  constructor(
    public readonly address: Address,
    public readonly abi: TAbi,
  ) {}

  protected async readContract<TResult = unknown>(
    functionName: ContractFunctionName<TAbi>,
    args: ContractFunctionArgs<TAbi> = [] as any,
  ): Promise<TResult> {
    const result = await readContract(wagmiConfig, {
      address: this.address,
      abi: this.abi,
      functionName,
      args,
    });
    return result as TResult;
  }

  protected async writeContract(
    functionName: ContractFunctionName<TAbi>,
    args: ContractFunctionArgs<TAbi> = [] as any,
    account?: Account,
  ) {
    return writeContract(wagmiConfig, {
      address: this.address,
      abi: this.abi,
      functionName,
      args,
      account,
    } as any);
  }
}

/**
 * Teller Client - Handles deposits, withdrawals, and share management
 */
export class TellerClient extends ContractClient<typeof CrestTellerAbi> {
  constructor() {
    super(Contracts.Crest.Teller, CrestTellerAbi);
  }

  // Deposit & Withdraw
  async deposit(assets: bigint, receiver: Address, account: Account) {
    return this.writeContract('deposit', [assets, receiver], account);
  }

  async withdraw(shares: bigint, receiver: Address, account: Account) {
    return this.writeContract('withdraw', [shares, receiver], account);
  }

  // Preview functions
  async previewDeposit(assets: bigint): Promise<bigint> {
    return this.readContract<bigint>('previewDeposit', [assets]);
  }

  async previewWithdraw(shares: bigint): Promise<bigint> {
    return this.readContract<bigint>('previewWithdraw', [shares]);
  }

  // Share lock functionality
  async areSharesLocked(user: Address): Promise<boolean> {
    return this.readContract<boolean>('areSharesLocked', [user]);
  }

  async getShareUnlockTime(user: Address): Promise<bigint> {
    return this.readContract<bigint>('getShareUnlockTime', [user]);
  }

  async getShareLockPeriod(): Promise<bigint> {
    return this.readContract<bigint>('shareLockPeriod');
  }

  // State queries
  async getVault(): Promise<Address> {
    return this.readContract<Address>('vault');
  }

  async getAccountant(): Promise<Address> {
    return this.readContract<Address>('accountant');
  }

  async getUsdt0(): Promise<Address> {
    return this.readContract<Address>('usdt0');
  }

  async getIsPaused(): Promise<boolean> {
    return this.readContract<boolean>('isPaused');
  }

  // Constants
  async getMinDeposit(): Promise<bigint> {
    return this.readContract<bigint>('MIN_DEPOSIT');
  }

  async getMinInitialShares(): Promise<bigint> {
    return this.readContract<bigint>('MIN_INITIAL_SHARES');
  }

  // Admin functions
  async pause(account: Account) {
    return this.writeContract('pause', [], account);
  }

  async unpause(account: Account) {
    return this.writeContract('unpause', [], account);
  }

  async setAccountant(accountant: Address, account: Account) {
    return this.writeContract('setAccountant', [accountant], account);
  }

  async setShareLockPeriod(period: bigint, account: Account) {
    return this.writeContract('setShareLockPeriod', [period], account);
  }
}

/**
 * Accountant Client - Handles exchange rates, fees, and asset/share conversions
 */
export class AccountantClient extends ContractClient<
  typeof CrestAccountantAbi
> {
  constructor() {
    super(Contracts.Crest.Accountant, CrestAccountantAbi);
  }

  // Asset/Share conversion
  async convertToShares(assets: bigint): Promise<bigint> {
    return this.readContract<bigint>('convertToShares', [assets]);
  }

  async convertToAssets(shares: bigint): Promise<bigint> {
    return this.readContract<bigint>('convertToAssets', [shares]);
  }

  // Exchange rate functions
  async getRate(): Promise<bigint> {
    return this.readContract<bigint>('getRate');
  }

  async canUpdateRate(): Promise<boolean> {
    return this.readContract<boolean>('canUpdateRate');
  }

  async timeUntilNextUpdate(): Promise<bigint> {
    return this.readContract<bigint>('timeUntilNextUpdate');
  }

  // Management functions
  async updateExchangeRate(totalAssets: bigint, account: Account) {
    return this.writeContract('updateExchangeRate', [totalAssets], account);
  }

  async collectFees(account: Account) {
    return this.writeContract('collectFees', [], account);
  }

  async updateFees(
    platformFeeBps: number,
    performanceFeeBps: number,
    account: Account,
  ) {
    return this.writeContract(
      'updateFees',
      [platformFeeBps, performanceFeeBps],
      account,
    );
  }

  async updateFeeRecipient(feeRecipient: Address, account: Account) {
    return this.writeContract('updateFeeRecipient', [feeRecipient], account);
  }

  async updateMaxRateChange(maxRateChangeBps: number, account: Account) {
    return this.writeContract(
      'updateMaxRateChange',
      [maxRateChangeBps],
      account,
    );
  }

  async updateRateUpdateCooldown(cooldown: bigint, account: Account) {
    return this.writeContract('updateRateUpdateCooldown', [cooldown], account);
  }

  async pause(account: Account) {
    return this.writeContract('pause', [], account);
  }

  async unpause(account: Account) {
    return this.writeContract('unpause', [], account);
  }

  // Getter properties
  get exchangeRate(): Promise<bigint> {
    return this.readContract<bigint>('exchangeRate');
  }

  get vault(): Promise<Address> {
    return this.readContract<Address>('vault');
  }

  get platformFeeBps(): Promise<number> {
    return this.readContract<number>('platformFeeBps');
  }

  get performanceFeeBps(): Promise<number> {
    return this.readContract<number>('performanceFeeBps');
  }

  get highWaterMark(): Promise<bigint> {
    return this.readContract<bigint>('highWaterMark');
  }

  get accumulatedPlatformFees(): Promise<bigint> {
    return this.readContract<bigint>('accumulatedPlatformFees');
  }

  get accumulatedPerformanceFees(): Promise<bigint> {
    return this.readContract<bigint>('accumulatedPerformanceFees');
  }

  get feeRecipient(): Promise<Address> {
    return this.readContract<Address>('feeRecipient');
  }

  get maxRateChangeBps(): Promise<number> {
    return this.readContract<number>('maxRateChangeBps');
  }

  get rateUpdateCooldown(): Promise<bigint> {
    return this.readContract<bigint>('rateUpdateCooldown');
  }

  get lastRateUpdate(): Promise<bigint> {
    return this.readContract<bigint>('lastRateUpdate');
  }

  get isPaused(): Promise<boolean> {
    return this.readContract<boolean>('isPaused');
  }
}

/**
 * Vault Client - ERC20 token functionality and vault management
 */
export class VaultClient extends ContractClient<typeof CrestVaultAbi> {
  // Role constants for access control
  static readonly DEFAULT_ADMIN_ROLE =
    '0x0000000000000000000000000000000000000000000000000000000000000000' as const;
  static readonly MANAGER_ROLE =
    '0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775' as const;

  constructor() {
    super(Contracts.Crest.Vault, CrestVaultAbi);
  }

  // ERC20 functions
  get name(): Promise<string> {
    return this.readContract<string>('name');
  }

  get symbol(): Promise<string> {
    return this.readContract<string>('symbol');
  }

  get decimals(): Promise<number> {
    return this.readContract<number>('decimals');
  }

  get totalSupply(): Promise<bigint> {
    return this.readContract<bigint>('totalSupply');
  }

  async balanceOf(account: Address): Promise<bigint> {
    return this.readContract<bigint>('balanceOf', [account]);
  }

  async allowance(owner: Address, spender: Address): Promise<bigint> {
    return this.readContract<bigint>('allowance', [owner, spender]);
  }

  async approve(spender: Address, amount: bigint, account: Account) {
    return this.writeContract('approve', [spender, amount], account);
  }

  async transfer(to: Address, amount: bigint, account: Account) {
    return this.writeContract('transfer', [to, amount], account);
  }

  async transferFrom(
    from: Address,
    to: Address,
    amount: bigint,
    account: Account,
  ) {
    return this.writeContract('transferFrom', [from, to, amount], account);
  }

  // Vault management
  async manage(
    target: Address,
    data: `0x${string}`,
    value: bigint,
    account: Account,
  ) {
    return this.writeContract('manage', [target, data, value], account);
  }

  async manageBatch(
    targets: Address[],
    data: `0x${string}`[],
    values: bigint[],
    account: Account,
  ) {
    return this.writeContract('manage', [targets, data, values], account);
  }

  async enter(
    from: Address,
    asset: Address,
    assetAmount: bigint,
    to: Address,
    shareAmount: bigint,
    account: Account,
  ) {
    return this.writeContract(
      'enter',
      [from, asset, assetAmount, to, shareAmount],
      account,
    );
  }

  async exit(
    to: Address,
    asset: Address,
    assetAmount: bigint,
    from: Address,
    shareAmount: bigint,
    account: Account,
  ) {
    return this.writeContract(
      'exit',
      [to, asset, assetAmount, from, shareAmount],
      account,
    );
  }

  // State queries

  // Authorization functions
  async getRoleAdmin(role: `0x${string}`): Promise<`0x${string}`> {
    return this.readContract<`0x${string}`>('getRoleAdmin', [role]);
  }

  async hasRole(role: `0x${string}`, account: Address): Promise<boolean> {
    return this.readContract<boolean>('hasRole', [role, account]);
  }

  async grantRole(role: `0x${string}`, account: Address, granter: Account) {
    return this.writeContract('grantRole', [role, account], granter);
  }

  async revokeRole(role: `0x${string}`, account: Address, revoker: Account) {
    return this.writeContract('revokeRole', [role, account], revoker);
  }

  async renounceRole(role: `0x${string}`, account: Account) {
    return this.writeContract('renounceRole', [role, account.address], account);
  }

  // Hook management
  async setBeforeTransferHook(hook: Address, account: Account) {
    return this.writeContract('setBeforeTransferHook', [hook], account);
  }

  // Getter properties
  get hook(): Promise<Address> {
    return this.readContract<Address>('hook');
  }

  get currentSpotIndex(): Promise<number> {
    return this.readContract<number>('currentSpotIndex');
  }

  get currentPerpIndex(): Promise<number> {
    return this.readContract<number>('currentPerpIndex');
  }
}

/**
 * Manager Client - Strategy execution and position management
 */
export class ManagerClient extends ContractClient<typeof CrestManagerAbi> {
  constructor() {
    super(Contracts.Crest.Manager, CrestManagerAbi);
  }

  // Strategy execution
  async closeAllPositions(account: Account) {
    return this.writeContract('closeAllPositions', [], account);
  }

  // Position queries
  async getPositions() {
    return this.readContract('getPositions');
  }

  async hasOpenPositions(): Promise<boolean> {
    return this.readContract<boolean>('hasOpenPositions');
  }

  async estimatePositionValue(): Promise<bigint> {
    return this.readContract<bigint>('estimatePositionValue');
  }

  async currentSpotPosition() {
    return this.readContract('currentSpotPosition');
  }

  async currentPerpPosition() {
    return this.readContract('currentPerpPosition');
  }


  // Management functions
  async updateCurator(curator: Address, account: Account) {
    return this.writeContract('updateCurator', [curator], account);
  }

  async updateMaxSlippage(maxSlippageBps: number, account: Account) {
    return this.writeContract('updateMaxSlippage', [maxSlippageBps], account);
  }

  async pause(account: Account) {
    return this.writeContract('pause', [], account);
  }

  async unpause(account: Account) {
    return this.writeContract('unpause', [], account);
  }

  // Getter properties
  get vault(): Promise<Address> {
    return this.readContract<Address>('vault');
  }

  get usdt0(): Promise<Address> {
    return this.readContract<Address>('usdt0');
  }

  get totalAllocated(): Promise<bigint> {
    return this.readContract<bigint>('totalAllocated');
  }

  get curator(): Promise<Address> {
    return this.readContract<Address>('curator');
  }

  get maxSlippageBps(): Promise<number> {
    return this.readContract<number>('maxSlippageBps');
  }

  get isPaused(): Promise<boolean> {
    return this.readContract<boolean>('isPaused');
  }

  get USDC_TOKEN_ID(): Promise<bigint> {
    return this.readContract<bigint>('USDC_TOKEN_ID');
  }

  get MARGIN_ALLOCATION_BPS(): Promise<number> {
    return this.readContract<number>('MARGIN_ALLOCATION_BPS');
  }

  get PERP_ALLOCATION_BPS(): Promise<number> {
    return this.readContract<number>('PERP_ALLOCATION_BPS');
  }

  get SPOT_ALLOCATION_BPS(): Promise<number> {
    return this.readContract<number>('SPOT_ALLOCATION_BPS');
  }
}

