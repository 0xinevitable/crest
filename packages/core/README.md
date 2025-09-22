# CrestVault - Delta-Neutral Hyperliquid Strategy

## Architecture

### Core Contracts

**CrestVault**

- ERC-4626 vault implementation with 6 decimal precision
- Authorization-based access control pattern
- Generic `manage()` function for strategy execution
- Tracks active Hyperliquid positions (spotIndex, perpIndex)

**CrestTeller**

- Deposit/withdrawal interface
- 1-day share lock period post-deposit (MEV protection)
- Minimum deposit: 1 USDT0

**CrestAccountant**

- Exchange rate calculation (6 decimal precision)
- Fee structure:
  - Platform fee: 1% annually (100 bps)
  - Performance fee: 5% on profits (500 bps)
- High water mark tracking
- 10% max rate change per update (manipulation protection)

**CrestManager**

- Strategy execution layer
- Allocation ratios:
  - 10% perp margin (1000 bps)
  - 45% spot long (4500 bps)
  - 45% perp short (4500 bps)
- IOC orders with 0.5% slippage tolerance
- Minimum balance requirement: 50 USDT0

## Strategy Logic

### Token Flow

```
USDT0 (EVM) → Bridge → USDT0 (Core) → Swap (spot 166) → USDC (Core)
→ Execute positions → PnL → Swap → USDT0 (Core) → Bridge → USDT0 (EVM)
```

### Position Management

1. **Entry**:
   - Bridge USDT0 to Hyperliquid Core
   - Swap USDT0 → USDC via spot index 166
   - Allocate USDC across margin/spot/perp
   - Place IOC orders with 0.5% slippage

2. **Delta-Neutral Construction**:
   - Long spot position (45%)
   - Short perp position (45%)
   - Net delta exposure: ~0

3. **Rebalancing**:
   - Close existing positions via IOC orders
   - Calculate realized PnL
   - Open new positions on target indexes

### Critical Implementation Details

- **USDT0 Selection**: USDC cannot be bridged on Hyperliquid; USDT0 (token ID 268) is bridgeable
- **Decimal Conversions**:
  - USDT0: 6 decimals (EVM) → 8 decimals (Core) via HLConversions
  - USDC: 6 decimals (EVM) → 8 decimals (Core), manual conversion (\*100)
- **Order Minimums**: Hyperliquid Core requires $10 minimum per order (using 20 USDT0 for safety)
- **USDT0 Address**: `0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb`

## Access Control & Authorization Matrix

### Authorization Flow

```
CrestVault (Owner)
    ├── authorizes → CrestTeller
    ├── authorizes → CrestManager
    └── authorizes → CrestAccountant

CrestTeller → calls vault.enter()/vault.exit()
CrestManager → calls vault.manage() to transfer funds
CrestAccountant → readonly (provides exchange rates)
```

### Role Permissions

| Contract            | Owner                                              | Curator                                            | Authorized | Public                                   |
| ------------------- | -------------------------------------------------- | -------------------------------------------------- | ---------- | ---------------------------------------- |
| **CrestVault**      | `authorize()`, `unauthorize()`, `setOwner()`       | -                                                  | `manage()` | View functions                           |
| **CrestTeller**     | `setAccountant()`, `pause()`, `unpause()`          | -                                                  | -          | `deposit()`, `withdraw()`                |
| **CrestManager**    | `setCurator()`, `pause()`, `unpause()`             | `allocate()`, `rebalance()`, `closeAllPositions()` | -          | View functions                           |
| **CrestAccountant** | `updateExchangeRate()`, `setFees()`, `claimFees()` | -                                                  | -          | `convertToShares()`, `convertToAssets()` |

## Core Functions

### CrestManager.allocate(uint32 spotIndex, uint32 perpIndex)

Opens new positions on Hyperliquid:

1. Validates no existing positions (`currentSpotPosition.size == 0`)
2. Checks minimum balance (50 USDT0)
3. Transfers USDT0 from vault via `vault.manage()`
4. Bridges USDT0 to Core
5. Swaps USDT0 → USDC on spot 166
6. Allocates: 10% margin, 45% spot long, 45% perp short
7. Places IOC orders with 0.5% slippage
8. Updates vault's tracking indexes

### CrestManager.rebalance(uint32 newSpotIndex, uint32 newPerpIndex)

Rotates positions to new assets:

1. Validates existing positions
2. Closes current positions via `_closeAllPositions()`:
   - Places IOC sell order for spot (0.5% below market)
   - Places IOC buy order for perp (0.5% above market)
   - Calculates realized PnL
3. Updates vault indexes to new targets
4. Does NOT automatically open new positions (requires separate `allocate()` call)

### CrestManager.closeAllPositions()

Exits all positions and returns funds:

1. Closes spot position (sell with IOC)
2. Closes perp position (buy to close short with IOC)
3. Swaps USDC → USDT0
4. Bridges USDT0 back to EVM
5. Emits `PositionClosed` events with realized PnL

### CrestTeller.deposit(uint256 assets, address receiver)

User deposits USDT0 for shares:

1. Calculates shares via `accountant.convertToShares()`
2. Transfers USDT0 to vault
3. Mints shares via `vault.enter()`
4. Sets 1-day lock: `shareUnlockTime[receiver] = block.timestamp + shareLockPeriod`

### CrestTeller.withdraw(uint256 shares, address receiver)

User withdraws USDT0 by burning shares:

1. Checks lock period: `block.timestamp >= shareUnlockTime[msg.sender]`
2. Calculates assets via `accountant.convertToAssets()`
3. Burns shares and transfers USDT0 via `vault.exit()`

### CrestAccountant.updateExchangeRate()

Updates share/asset exchange rate:

1. Calculates total value (vault balance + positions)
2. Applies platform fee (1% annually)
3. Calculates performance fee if above high water mark (5% of profit)
4. Enforces 10% max rate change
5. Updates `exchangeRate` and `highWaterMark`

## Security

- ReentrancyGuard on all state-changing operations
- 1-day withdrawal lock (shareUnlockTime mapping)
- Pausable pattern on Teller and Manager
- Maximum rate change limits (10%)
- Minimum thresholds prevent dust attacks

## Testing

```bash
# Fork Hyperliquid mainnet
forge test --fork-url https://rpc.hyperliquid.xyz/evm

# Use vm.deal() to allocate USDT0 in tests
deal(USDT0_ADDRESS, user, amount);
```

## Deployment

Requires sequential deployment:

1. Deploy CrestVault
2. Deploy CrestAccountant with vault address
3. Deploy CrestTeller with vault and USDT0 addresses
4. Deploy CrestManager with vault and USDT0 addresses
5. Authorize Teller and Manager on Vault
6. Set Accountant on Teller
7. Set fee recipient on Accountant

```env
PRIVATE_KEY=0x0
CURATOR_ADDRESS=0x0
FEE_RECIPIENT_ADDRESS=0x0
```

```bash
# dry run
forge script script/Deploy.s.sol --rpc-url https://rpc.hyperliquid-testnet.xyz/evm

# broadcast
forge script script/Deploy.s.sol --rpc-url https://rpc.hyperliquid-testnet.xyz/evm --broadcast
```

## wip

```bash
# facet update
 forge script script/UpgradeVaultFacet.s.sol --rpc-url https://rpc.hyperliquid.xyz/evm --broadcast

# self auth
forge script script/AuthorizeDiamond.s.sol --rpc-url https://rpc.hyperliquid.xyz/evm --broadcast -vvv
```
