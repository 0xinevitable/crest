import { parseAbi } from 'viem';

// ========================================= COMMON ABI FRAGMENTS =========================================

/**
 * Standard ERC20 token functions and events
 */
export const ERC20_ABI_FRAGMENT = [
  // View functions
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address account) view returns (uint256)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  
  // Write functions
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function transfer(address to, uint256 amount) external returns (bool)',
  'function transferFrom(address from, address to, uint256 amount) external returns (bool)',
  
  // Events
  'event Transfer(address indexed from, address indexed to, uint256 value)',
  'event Approval(address indexed owner, address indexed spender, uint256 value)',
] as const;

/**
 * Pausable pattern for contracts that can be paused/unpaused
 */
export const PAUSABLE_ABI_FRAGMENT = [
  // State queries
  'function isPaused() view returns (bool)',
  
  // Admin functions
  'function pause() external',
  'function unpause() external',
  
  // Events
  'event Paused()',
  'event Unpaused()',
] as const;

/**
 * Authorization pattern for access control
 */
export const AUTHORIZATION_ABI_FRAGMENT = [
  // View functions
  'function owner() view returns (address)',
  'function authorized(address) view returns (bool)',
  
  // Write functions
  'function authorize(address target) external',
  'function unauthorize(address target) external',
] as const;

/**
 * Allocation pattern for position management
 */
export const ALLOCATION_ABI_FRAGMENT = [
  // Core functions
  'function allocate(uint32 spotIndex, uint32 perpIndex) external',
  'function rebalance(uint32 newSpotIndex, uint32 newPerpIndex) external',
  
  // Events
  'event Allocation(uint32 spotIndex, uint32 perpIndex, uint256 amount)',
  'event Rebalance(uint32 oldSpotIndex, uint32 oldPerpIndex, uint32 newSpotIndex, uint32 newPerpIndex)',
] as const;

// ========================================= UTILITY FUNCTIONS =========================================

/**
 * Combines multiple ABI fragments into a single parsed ABI
 */
export function combineAbiFragments(...fragments: ReadonlyArray<readonly string[]>) {
  const combined = fragments.flat();
  return parseAbi(combined);
}

/**
 * Creates a parsed ABI with specific fragments
 */
export function createAbi(baseFragments: readonly string[], ...additionalFragments: ReadonlyArray<readonly string[]>) {
  return combineAbiFragments(baseFragments, ...additionalFragments);
}

// ========================================= TELLER ABI =========================================

const TELLER_SPECIFIC_ABI = [
  // Core deposit/withdraw functions
  'function deposit(uint256 assets, address receiver) external returns (uint256)',
  'function withdraw(uint256 shares, address receiver) external returns (uint256)',

  // Preview functions
  'function previewDeposit(uint256 assets) view returns (uint256)',
  'function previewWithdraw(uint256 shares) view returns (uint256)',

  // Share lock functionality
  'function areSharesLocked(address user) view returns (bool)',
  'function getShareUnlockTime(address user) view returns (uint256)',
  'function shareLockPeriod() view returns (uint64)',

  // Admin functions
  'function setAccountant(address _accountant) external',
  'function setShareLockPeriod(uint64 _period) external',

  // State queries
  'function vault() view returns (address)',
  'function accountant() view returns (address)',
  'function usdt0() view returns (address)',
  'function shareUnlockTime(address) view returns (uint256)',

  // Constants
  'function MIN_DEPOSIT() view returns (uint256)',
  'function MIN_INITIAL_SHARES() view returns (uint256)',

  // Events
  'event Deposit(address indexed user, uint256 assets, uint256 shares)',
  'event Withdraw(address indexed user, uint256 assets, uint256 shares)',
  'event AccountantUpdated(address indexed accountant)',
  'event ShareLockPeriodUpdated(uint64 period)',
] as const;

export const CrestTellerAbi = createAbi(TELLER_SPECIFIC_ABI, PAUSABLE_ABI_FRAGMENT);

// ========================================= ACCOUNTANT ABI =========================================

const ACCOUNTANT_SPECIFIC_ABI = [
  // Asset/Share conversion
  'function convertToShares(uint256 assets) view returns (uint256)',
  'function convertToAssets(uint256 shares) view returns (uint256)',

  // Exchange rate functions
  'function getRate() view returns (uint256)',
  'function canUpdateRate() view returns (bool)',
  'function timeUntilNextUpdate() view returns (uint256)',

  // Core management functions
  'function updateExchangeRate(uint256 totalAssets) external',
  'function collectFees() external',

  // Fee management
  'function updateFees(uint16 _platformFeeBps, uint16 _performanceFeeBps) external',
  'function updateFeeRecipient(address _feeRecipient) external',

  // Rate management
  'function updateMaxRateChange(uint16 _maxRateChangeBps) external',
  'function updateRateUpdateCooldown(uint64 _cooldown) external',

  // State queries
  'function vault() view returns (address)',
  'function exchangeRate() view returns (uint96)',
  'function platformFeeBps() view returns (uint16)',
  'function performanceFeeBps() view returns (uint16)',
  'function highWaterMark() view returns (uint96)',
  'function accumulatedPlatformFees() view returns (uint256)',
  'function accumulatedPerformanceFees() view returns (uint256)',
  'function feeRecipient() view returns (address)',
  'function maxRateChangeBps() view returns (uint16)',
  'function rateUpdateCooldown() view returns (uint64)',
  'function lastRateUpdate() view returns (uint64)',

  // Events
  'event RateUpdated(uint96 oldRate, uint96 newRate, uint256 platformFees, uint256 performanceFees)',
  'event FeesUpdated(uint16 platformFeeBps, uint16 performanceFeeBps)',
  'event FeeRecipientUpdated(address indexed recipient)',
  'event FeesCollected(address indexed recipient, uint256 platformFees, uint256 performanceFees)',
  'event MaxRateChangeUpdated(uint16 bps)',
  'event RateUpdateCooldownUpdated(uint64 cooldown)',
] as const;

export const CrestAccountantAbi = createAbi(ACCOUNTANT_SPECIFIC_ABI, PAUSABLE_ABI_FRAGMENT);

// ========================================= VAULT ABI =========================================

const VAULT_SPECIFIC_ABI = [
  // Vault management functions
  'function manage(address target, bytes calldata data, uint256 value) external returns (bytes memory)',
  'function manage(address[] calldata targets, bytes[] calldata data, uint256[] calldata values) external returns (bytes[] memory)',

  // Vault operations
  'function enter(address from, address asset, uint256 assetAmount, address to, uint256 shareAmount) external',
  'function exit(address to, address asset, uint256 assetAmount, address from, uint256 shareAmount) external',

  // Hook management
  'function setBeforeTransferHook(address _hook) external',

  // Vault-specific state
  'function hook() view returns (address)',
  'function currentSpotIndex() view returns (uint32)',
  'function currentPerpIndex() view returns (uint32)',

  // Events
  'event Enter(address indexed from, address indexed asset, uint256 amount, address indexed to, uint256 shares)',
  'event Exit(address indexed to, address indexed asset, uint256 amount, address indexed from, uint256 shares)',
] as const;

export const CrestVaultAbi = createAbi(
  VAULT_SPECIFIC_ABI, 
  ERC20_ABI_FRAGMENT, 
  AUTHORIZATION_ABI_FRAGMENT, 
  ALLOCATION_ABI_FRAGMENT
);

// ========================================= MANAGER ABI =========================================

const MANAGER_SPECIFIC_ABI = [
  // Core strategy execution functions
  'function closeAllPositions() external',

  // Position queries
  'function getPositions() view returns ((uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp), (uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp))',
  'function hasOpenPositions() view returns (bool)',
  'function estimatePositionValue() view returns (uint256)',

  // Position details
  'function currentSpotPosition() view returns (uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp)',
  'function currentPerpPosition() view returns (uint32 index, bool isLong, uint64 size, uint64 entryPrice, uint256 timestamp)',

  // Management functions
  'function updateCurator(address _curator) external',
  'function updateMaxSlippage(uint16 _maxSlippageBps) external',

  // State queries
  'function vault() view returns (address)',
  'function usdt0() view returns (address)',
  'function totalAllocated() view returns (uint256)',
  'function curator() view returns (address)',
  'function maxSlippageBps() view returns (uint16)',

  // Constants
  'function USDC_TOKEN_ID() view returns (uint64)',
  'function MARGIN_ALLOCATION_BPS() view returns (uint16)',
  'function PERP_ALLOCATION_BPS() view returns (uint16)',
  'function SPOT_ALLOCATION_BPS() view returns (uint16)',

  // Events
  'event Allocated(uint32 spotIndex, uint32 perpIndex, uint256 totalAmount, uint256 marginAmount, uint256 spotAmount, uint256 perpAmount)',
  'event Rebalanced(uint32 oldSpotIndex, uint32 oldPerpIndex, uint32 newSpotIndex, uint32 newPerpIndex)',
  'event PositionClosed(bool isSpot, uint32 index, uint256 realizedPnL)',
  'event CuratorUpdated(address indexed curator)',
  'event MaxSlippageUpdated(uint16 bps)',
] as const;

export const CrestManagerAbi = createAbi(
  MANAGER_SPECIFIC_ABI, 
  ALLOCATION_ABI_FRAGMENT, 
  PAUSABLE_ABI_FRAGMENT
);

