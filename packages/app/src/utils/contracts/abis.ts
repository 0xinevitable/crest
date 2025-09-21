import { parseAbi } from 'viem';

export const CrestTellerAbi = parseAbi([
  // View functions for deposits and withdrawals
  'function previewDeposit(uint256 assets) view returns (uint256)',
  'function previewWithdraw(uint256 shares) view returns (uint256)',

  // Share lock functionality
  'function areSharesLocked(address user) view returns (bool)',
  'function getShareUnlockTime(address user) view returns (uint256)',
  'function shareLockPeriod() view returns (uint64)',

  // State queries
  'function isPaused() view returns (bool)',
  'function accountant() view returns (address)',
  'function vault() view returns (address)',
  'function usdt0() view returns (address)',
]);

export const CrestAccountantAbi = parseAbi([
  // Asset/Share conversion
  'function convertToShares(uint256 assets) view returns (uint256)',
  'function convertToAssets(uint256 shares) view returns (uint256)',

  // Exchange rate functions
  'function getRate() view returns (uint256)',
  'function canUpdateRate() view returns (bool)',
  'function timeUntilNextUpdate() view returns (uint256)',

  // Fee information
  'function platformFeeBps() view returns (uint16)',
  'function performanceFeeBps() view returns (uint16)',
  'function highWaterMark() view returns (uint96)',
  'function accumulatedPlatformFees() view returns (uint256)',
  'function accumulatedPerformanceFees() view returns (uint256)',

  // State queries
  'function exchangeRate() view returns (uint96)',
  'function lastRateUpdate() view returns (uint256)',
  'function rateUpdateCooldown() view returns (uint256)',
  'function vault() view returns (address)',
]);

export const CrestVaultAbi = parseAbi([
  // Standard ERC20 view functions
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address account) view returns (uint256)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',

  // Vault-specific state
  'function currentSpotIndex() view returns (uint32)',
  'function currentPerpIndex() view returns (uint32)',
  'function hook() view returns (address)',
  'function owner() view returns (address)',
  'function authorized(address) view returns (bool)',
]);

export const CrestManagerAbi = parseAbi([
  // Position queries
  'function getPositions() view returns ((uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp), (uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp))',
  'function hasOpenPositions() view returns (bool)',
  'function estimatePositionValue() view returns (uint256)',

  // State queries
  'function totalAllocated() view returns (uint256)',
  'function isPaused() view returns (bool)',
  'function curator() view returns (address)',
  'function maxSlippageBps() view returns (uint16)',
  'function vault() view returns (address)',
  'function usdt0() view returns (address)',

  // Position details
  'function currentSpotPosition() view returns (uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp)',
  'function currentPerpPosition() view returns (uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp)',

  // Constants
  'function USDC_TOKEN_ID() view returns (uint64)',
  'function MARGIN_ALLOCATION_BPS() view returns (uint16)',
  'function PERP_ALLOCATION_BPS() view returns (uint16)',
  'function SPOT_ALLOCATION_BPS() view returns (uint16)',
]);
