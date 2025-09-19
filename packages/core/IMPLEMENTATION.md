# CrestVault Implementation

## Overview

CrestVault is a modular DeFi vault system built on the BoringVault architecture that allocates funds to Hyperliquid spot and perpetual markets. The system follows a delta-neutral strategy by maintaining long spot and short perp positions.

## Architecture

The implementation follows the BoringVault modular architecture with four core components:

### 1. CrestVault (src/CrestVault.sol)
- **Core vault contract** with minimal logic (~100 lines of critical code)
- Inherits from ERC20 for share tokens
- Manages funds and delegates complexity to external modules
- Supports arbitrary external calls through `manage()` functions
- Tracks current allocation indexes for Hyperliquid

### 2. CrestTeller (src/CrestTeller.sol)
- **User-facing interface** for deposits and withdrawals
- Handles USDC deposits and share minting
- Enforces share lock periods (default 1 day)
- Includes pause functionality for emergency situations
- Minimum deposit: 1 USDC

### 3. CrestAccountant (src/CrestAccountant.sol)
- **Exchange rate calculation** and fee management
- Tracks vault performance and updates share prices
- Platform fee: 2% (configurable)
- Performance fee: 20% above high water mark (configurable)
- Rate change limits: Max 10% per update
- Update cooldown: 1 hour minimum between updates

### 4. CrestManager (src/CrestManager.sol)
- **Hyperliquid integration** and position management
- Allocation strategy:
  - 10% to Hyperliquid margin account
  - 45% to long spot position
  - 45% to short perp position
- Handles rebalancing between different assets
- Curator-controlled allocations

## Allocation Strategy

The vault implements a delta-neutral strategy:

1. **Initial Allocation** (when curator calls `allocate()`):
   - Bridges 100% of USDC to Hyperliquid
   - Transfers 10% to perp margin account
   - Opens 45% long spot position
   - Opens 45% short perp position

2. **Rebalancing** (when curator calls `rebalance()`):
   - Closes existing positions
   - Calculates PnL
   - Opens new positions in different markets

3. **Position Management**:
   - Uses limit orders with GTC (Good Till Cancelled) time-in-force
   - Tracks entry prices for PnL calculation
   - Supports emergency position closure

## Security Features

1. **Access Control**:
   - Owner controls administrative functions
   - Curator controls allocations and rebalancing
   - Modular auth system for role-based permissions

2. **Safety Mechanisms**:
   - Share lock periods prevent immediate withdrawals
   - Pause functionality on all critical modules
   - Rate change limits prevent manipulation
   - Minimum deposit requirements

3. **Fee Structure**:
   - Transparent fee calculation
   - High water mark for performance fees
   - Accumulated fees collected separately

## Testing

The test suite (`test/CrestVault.t.sol`) covers:
- Deposit and withdrawal flows
- Share lock mechanisms
- Allocation to Hyperliquid positions
- Rebalancing between markets
- Exchange rate updates
- Fee collection
- Pause functionality
- Position value estimation

## Deployment

Use the deployment script:
```bash
forge script script/DeployCrestVault.s.sol --rpc-url https://rpc.hyperliquid.xyz/evm --broadcast
```

Required environment variables:
- `PRIVATE_KEY`: Deployer's private key
- `CURATOR_ADDRESS`: Address allowed to trigger allocations
- `FEE_RECIPIENT_ADDRESS`: Address to receive fees

## Integration with Hyperliquid

The system uses the `hyper-evm-lib` library for Hyperliquid integration:

1. **CoreWriterLib**: Handles bridging and order placement
2. **PrecompileLib**: Queries prices and account information
3. **HLConversions**: Manages decimal conversions between EVM and Hyperliquid

Key precompile addresses:
- CoreWriter: `0x3333333333333333333333333333333333333333`
- HYPE System: `0x2222222222222222222222222222222222222222`
- Base System: `0x4444444444444444444444444444444444444444`

## Usage Flow

1. **User Deposits**:
   ```solidity
   usdc.approve(teller, amount);
   teller.deposit(amount, receiver);
   ```

2. **Curator Allocates**:
   ```solidity
   manager.allocate(spotIndex, perpIndex);
   ```

3. **Periodic Rebalancing**:
   ```solidity
   manager.rebalance(newSpotIndex, newPerpIndex);
   ```

4. **User Withdraws** (after lock period):
   ```solidity
   teller.withdraw(shares, receiver);
   ```

5. **Update Exchange Rate**:
   ```solidity
   accountant.updateExchangeRate(totalAssets);
   ```

## Next Steps

1. **Audit Considerations**:
   - Review access control mechanisms
   - Validate Hyperliquid integration
   - Test edge cases for allocations
   - Verify decimal handling

2. **Enhancements**:
   - Add more sophisticated rebalancing strategies
   - Implement automated rebalancing triggers
   - Add support for multiple assets
   - Enhance reporting and analytics

3. **Production Deployment**:
   - Deploy to testnet first
   - Conduct thorough testing with small amounts
   - Gradually increase allocation limits
   - Monitor position performance

## Contract Addresses (To be filled after deployment)

- Vault: `0x...`
- Teller: `0x...`
- Accountant: `0x...`
- Manager: `0x...`