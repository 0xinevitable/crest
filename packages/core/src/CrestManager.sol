// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from '@solmate/tokens/ERC20.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeTransferLib } from '@solmate/utils/SafeTransferLib.sol';
import { FixedPointMathLib } from '@solmate/utils/FixedPointMathLib.sol';
import { Auth, Authority } from '@solmate/auth/Auth.sol';
import { ReentrancyGuard } from '@solmate/utils/ReentrancyGuard.sol';
import { CrestVault } from './CrestVault.sol';
import { PrecompileLib } from '@hyper-evm-lib/src/PrecompileLib.sol';
import { HLConstants } from '@hyper-evm-lib/src/common/HLConstants.sol';
import { HLConversions } from '@hyper-evm-lib/src/common/HLConversions.sol';
import { CoreWriterLib } from '@hyper-evm-lib/src/CoreWriterLib.sol';

contract CrestManager is Auth, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    // No using statement needed for library calls

    // ========================================= CONSTANTS =========================================

    /**
     * @notice USDC token ID on Hyperliquid Core (for trading)
     */
    uint64 public constant USDC_TOKEN_ID = 0;

    uint256 public constant TESTNET_CHAINID = 998;

    /**
     * @notice USDT0 token ID on Hyperliquid Core (bridgeable)
     */
    function usdt0TokenId() internal view returns (uint64) {
        return block.chainid == TESTNET_CHAINID ? 1204 : 268;
    }

    /**
     * @notice USDT0/USDC spot index for swapping
     */
    function usdt0SpotIndex() internal view returns (uint32) {
        return block.chainid == TESTNET_CHAINID ? 1115 : 166;
    }

    /**
     * @notice Allocation percentages (basis points)
     */
    uint16 public constant MARGIN_ALLOCATION_BPS = 1000; // 10%
    uint16 public constant PERP_ALLOCATION_BPS = 4500; // 45%
    uint16 public constant SPOT_ALLOCATION_BPS = 4500; // 45%

    /**
     * @notice Maximum slippage allowed (basis points)
     */
    uint16 public maxSlippageBps = 100; // 1%

    // ========================================= STATE =========================================

    /**
     * @notice The CrestVault contract
     */
    CrestVault public immutable vault;

    /**
     * @notice The USDT0 token contract (what users deposit)
     */
    ERC20 public immutable usdt0;

    /**
     * @notice Current positions
     */
    struct Position {
        uint32 index;
        bool isLong;
        uint64 size;
        uint64 entryPrice;
        uint256 timestamp;
    }

    Position public currentSpotPosition;
    Position public currentPerpPosition;

    /**
     * @notice Total USDC allocated to Hyperliquid
     */
    uint256 public totalAllocated;

    /**
     * @notice Pauses allocations and rebalancing
     */
    bool public isPaused;

    /**
     * @notice Curator address allowed to trigger allocations
     */
    address public curator;

    //============================== EVENTS ===============================

    event Allocated(
        uint32 spotIndex,
        uint32 perpIndex,
        uint256 totalAmount,
        uint256 marginAmount,
        uint256 spotAmount,
        uint256 perpAmount
    );
    event Rebalanced(
        uint32 oldSpotIndex,
        uint32 oldPerpIndex,
        uint32 newSpotIndex,
        uint32 newPerpIndex
    );
    event PositionClosed(bool isSpot, uint32 index, uint256 realizedPnL);
    event CuratorUpdated(address indexed curator);
    event MaxSlippageUpdated(uint16 bps);
    event Paused();
    event Unpaused();

    //============================== ERRORS ===============================

    error CrestManager__Paused();
    error CrestManager__Unauthorized();
    error CrestManager__InsufficientBalance();
    error CrestManager__InvalidIndex();
    error CrestManager__SlippageTooHigh();
    error CrestManager__PositionAlreadyOpen();
    error CrestManager__NoPositionToClose();

    //============================== MODIFIERS ===============================

    modifier whenNotPaused() {
        if (isPaused) revert CrestManager__Paused();
        _;
    }

    modifier onlyCurator() {
        if (msg.sender != curator && msg.sender != owner)
            revert CrestManager__Unauthorized();
        _;
    }

    //============================== CONSTRUCTOR ===============================

    constructor(
        address payable _vault,
        address _usdt0,
        address _owner,
        address _curator
    ) Auth(_owner, Authority(address(0))) {
        vault = CrestVault(_vault);
        usdt0 = ERC20(_usdt0);
        curator = _curator;
    }

    //============================== ALLOCATION FUNCTIONS ===============================

    /**
     * @notice Allocates vault funds to Hyperliquid positions
     * @param spotIndex The spot market index to buy
     * @param perpIndex The perp market index to short
     */
    function allocate(
        uint32 spotIndex,
        uint32 perpIndex
    ) external onlyCurator whenNotPaused nonReentrant {
        // Check if positions are already open
        if (currentSpotPosition.size > 0 || currentPerpPosition.size > 0) {
            revert CrestManager__PositionAlreadyOpen();
        }

        // Get available USDT0 balance
        uint256 availableUsdt0 = usdt0.balanceOf(address(vault));

        // Check if we need to withdraw from Hyperdrive
        uint256 hyperdriveValue = vault.getHyperdriveValue();
        if (hyperdriveValue > 0 && availableUsdt0 < 50e6) {
            // Withdraw all from Hyperdrive for allocation
            vault.withdrawFromHyperdrive(type(uint256).max);
            // Update vault balance after withdrawal
            availableUsdt0 = usdt0.balanceOf(address(vault));
        }

        // Minimum 50 USDT0 needed to meet Core's minimum order requirements (20 USDT0)
        if (availableUsdt0 < 50e6) revert CrestManager__InsufficientBalance();

        // Calculate allocations
        uint256 marginAmount = (availableUsdt0 * MARGIN_ALLOCATION_BPS) / 10000;
        uint256 spotAmount = (availableUsdt0 * SPOT_ALLOCATION_BPS) / 10000;
        uint256 perpAmount = (availableUsdt0 * PERP_ALLOCATION_BPS) / 10000;

        // Get current prices from Hyperliquid precompiles
        uint64 spotPrice = PrecompileLib.spotPx(uint64(spotIndex));
        uint64 perpPrice = PrecompileLib.markPx(perpIndex);

        // Transfer USDT0 from vault to this contract first
        bytes memory transferData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            address(this),
            marginAmount + spotAmount + perpAmount
        );
        vault.manage(address(usdt0), transferData, 0);

        // Bridge USDT0 to Hyperliquid core
        CoreWriterLib.bridgeToCore(
            address(usdt0),
            marginAmount + spotAmount + perpAmount
        );

        // Swap USDT0 to USDC on Hyperliquid
        uint64 usdt0CoreAmount = HLConversions.evmToWei(
            usdt0TokenId(),
            marginAmount + spotAmount + perpAmount
        );

        // Place market order to sell USDT0 for USDC
        CoreWriterLib.placeLimitOrder(
            usdt0SpotIndex(),
            false, // sell USDT0
            PrecompileLib.spotPx(usdt0SpotIndex()) - 10, // slight slippage for immediate fill
            usdt0CoreAmount,
            false, // not reduce only
            3, // IOC
            uint128(block.timestamp << 32) // unique cloid
        );

        // After swap, we have USDC in spot balance
        // Transfer margin to perp account
        // USDC: 6 decimals on EVM, 8 decimals in Core
        uint64 marginCoreAmount = uint64(marginAmount) * 100; // Convert 6 decimals to 8 decimals
        CoreWriterLib.transferUsdClass(
            marginCoreAmount, // In Core's 8 decimal format
            true // to perp
        );

        // Place spot buy order
        {
            // Convert spot amount from EVM to Core decimals
            // USDC: 6 decimals on EVM, 8 decimals in Core
            uint64 spotSizeCoreAmount = uint64(spotAmount) * 100;
            // Calculate how many tokens we can buy with this USDC amount
            uint64 spotSizeInAsset = uint64(
                (uint256(spotSizeCoreAmount) * 1e8) / spotPrice
            );

            // Place spot buy order with slippage for immediate execution
            CoreWriterLib.placeLimitOrder(
                spotIndex,
                true, // isBuy
                spotPrice + ((spotPrice * 50) / 10000), // 0.5% slippage
                spotSizeInAsset,
                false, // reduceOnly
                3, // IOC (Immediate or Cancel)
                uint128(block.timestamp) // cloid
            );

            // Update spot position
            currentSpotPosition.index = spotIndex;
            currentSpotPosition.isLong = true;
            currentSpotPosition.size = spotSizeInAsset;
            currentSpotPosition.entryPrice = spotPrice;
            currentSpotPosition.timestamp = block.timestamp;
        }

        // Place perp short order
        {
            // Convert perp amount from EVM to Core decimals
            // USDC: 6 decimals on EVM, 8 decimals in Core
            uint64 perpSizeCoreAmount = uint64(perpAmount) * 100;
            // Calculate position size in contracts
            uint64 perpSizeInAsset = uint64(
                (uint256(perpSizeCoreAmount) * 1e6) / perpPrice
            );

            // Place perp short order with slippage for immediate execution
            CoreWriterLib.placeLimitOrder(
                perpIndex,
                false, // isBuy (short)
                perpPrice - ((perpPrice * 50) / 10000), // 0.5% slippage
                perpSizeInAsset,
                false, // reduceOnly
                3, // IOC (Immediate or Cancel)
                uint128(block.timestamp + 1) // cloid
            );

            // Update perp position
            currentPerpPosition.index = perpIndex;
            currentPerpPosition.isLong = false;
            currentPerpPosition.size = perpSizeInAsset;
            currentPerpPosition.entryPrice = perpPrice;
            currentPerpPosition.timestamp = block.timestamp;
        }

        totalAllocated = marginAmount + spotAmount + perpAmount;

        // Update vault indexes
        vault.allocate(spotIndex, perpIndex);

        emit Allocated(
            spotIndex,
            perpIndex,
            totalAllocated,
            marginAmount,
            spotAmount,
            perpAmount
        );
    }

    /**
     * @notice Rebalances the vault to new positions
     * @param newSpotIndex The new spot market index
     * @param newPerpIndex The new perp market index
     */
    function rebalance(
        uint32 newSpotIndex,
        uint32 newPerpIndex
    ) external onlyCurator whenNotPaused nonReentrant {
        // Check if there are any positions to rebalance
        if (currentSpotPosition.index == 0 && currentPerpPosition.index == 0) {
            revert CrestManager__NoPositionToClose();
        }

        uint32 oldSpotIndex = currentSpotPosition.index;
        uint32 oldPerpIndex = currentPerpPosition.index;

        // Close existing positions but keep funds in Core for reallocation
        if (currentSpotPosition.size > 0 || currentPerpPosition.size > 0) {
            _closePositionsOnly();
        }

        // Now reallocate to new positions (funds are still in Core as USDC)
        _openPositions(newSpotIndex, newPerpIndex);

        // Update vault state
        vault.rebalance(newSpotIndex, newPerpIndex);

        emit Rebalanced(oldSpotIndex, oldPerpIndex, newSpotIndex, newPerpIndex);
    }

    /**
     * @notice Exits all positions and bridges funds back to vault
     */
    function exit() external onlyCurator whenNotPaused nonReentrant {
        // Close all positions
        _closePositionsOnly();

        // Bridge everything back to EVM
        _bridgeBackToVault();

        totalAllocated = 0;
    }

    /**
     * @notice Internal function to close positions without bridging back
     */
    function _closePositionsOnly() internal {
        // Close spot position
        if (currentSpotPosition.size > 0) {
            // Get current spot price from precompile
            uint64 currentSpotPrice = PrecompileLib.spotPx(
                uint64(currentSpotPosition.index)
            );

            // Sell with slippage for immediate execution
            CoreWriterLib.placeLimitOrder(
                currentSpotPosition.index,
                false, // isBuy (sell to close)
                currentSpotPrice - ((currentSpotPrice * 50) / 10000), // 0.5% below market for immediate fill
                currentSpotPosition.size,
                true, // reduceOnly
                3, // IOC
                uint128(block.timestamp + 2) // cloid
            );

            // Calculate PnL
            int256 spotPnL;
            if (currentSpotPrice >= currentSpotPosition.entryPrice) {
                spotPnL =
                    (int256(
                        uint256(
                            currentSpotPrice - currentSpotPosition.entryPrice
                        )
                    ) * int256(uint256(currentSpotPosition.size))) / 1e8;
            } else {
                spotPnL =
                    (-int256(
                        uint256(
                            currentSpotPosition.entryPrice - currentSpotPrice
                        )
                    ) * int256(uint256(currentSpotPosition.size))) / 1e8;
            }

            emit PositionClosed(
                true,
                currentSpotPosition.index,
                uint256(spotPnL > 0 ? spotPnL : -spotPnL)
            );

            currentSpotPosition.size = 0;
            currentSpotPosition.entryPrice = 0;
        }

        // Close perp position
        if (currentPerpPosition.size > 0) {
            // Get current perp mark price from precompile
            uint64 currentPerpPrice = PrecompileLib.markPx(
                currentPerpPosition.index
            );

            // Buy to close short with slippage for immediate execution
            CoreWriterLib.placeLimitOrder(
                currentPerpPosition.index,
                true, // isBuy (buy to close short)
                currentPerpPrice + ((currentPerpPrice * 50) / 10000), // 0.5% above market for immediate fill
                currentPerpPosition.size,
                true, // reduceOnly
                3, // IOC
                uint128(block.timestamp + 3) // cloid
            );

            // Calculate PnL (inverted for short)
            int256 perpPnL;
            if (currentPerpPosition.entryPrice >= currentPerpPrice) {
                perpPnL =
                    (int256(
                        uint256(
                            currentPerpPosition.entryPrice - currentPerpPrice
                        )
                    ) * int256(uint256(currentPerpPosition.size))) / 1e6;
            } else {
                perpPnL =
                    (-int256(
                        uint256(
                            currentPerpPrice - currentPerpPosition.entryPrice
                        )
                    ) * int256(uint256(currentPerpPosition.size))) / 1e6;
            }

            emit PositionClosed(
                false,
                currentPerpPosition.index,
                uint256(perpPnL > 0 ? perpPnL : -perpPnL)
            );

            currentPerpPosition.size = 0;
            currentPerpPosition.entryPrice = 0;
        }

        // After closing positions, move any funds from perp back to spot account
        // This is needed for rebalancing to have all USDC available in spot
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(this));

        if (marginSummary.accountValue > 0) {
            uint64 perpUsdAmount = uint64(marginSummary.accountValue);
            CoreWriterLib.transferUsdClass(perpUsdAmount, false); // from perp to spot
        }
    }

    /**
     * @notice Opens new positions with available USDC in Core
     */
    function _openPositions(uint32 spotIndex, uint32 perpIndex) internal {
        // Always update indexes
        currentSpotPosition.index = spotIndex;
        currentPerpPosition.index = perpIndex;
        currentSpotPosition.timestamp = block.timestamp;
        currentPerpPosition.timestamp = block.timestamp;

        // Get available USDC balance in Core
        PrecompileLib.SpotBalance memory usdcBalance = PrecompileLib
            .spotBalance(address(this), USDC_TOKEN_ID);

        if (usdcBalance.total == 0) return;

        // Convert USDC balance from Core to EVM decimals
        uint256 totalUsdc = HLConversions.weiToEvm(USDC_TOKEN_ID, uint64(usdcBalance.total));
        uint256 marginAmount = (totalUsdc * MARGIN_ALLOCATION_BPS) / 10000;
        uint256 spotAmount = (totalUsdc * SPOT_ALLOCATION_BPS) / 10000;
        uint256 perpAmount = (totalUsdc * PERP_ALLOCATION_BPS) / 10000;

        // Get current prices
        uint64 spotPrice = PrecompileLib.spotPx(uint64(spotIndex));
        uint64 perpPrice = PrecompileLib.markPx(perpIndex);

        // Transfer margin to perp account
        // Convert USDC from EVM decimals to Core decimals
        uint64 marginCoreAmount = HLConversions.evmToWei(USDC_TOKEN_ID, marginAmount);
        CoreWriterLib.transferUsdClass(marginCoreAmount, true);

        // Place spot buy order
        // Convert USDC from EVM decimals to Core decimals
        uint64 spotSizeCoreAmount = HLConversions.evmToWei(USDC_TOKEN_ID, spotAmount);
        uint64 spotSizeInAsset = uint64(
            (uint256(spotSizeCoreAmount) * 1e8) / spotPrice
        );

        CoreWriterLib.placeLimitOrder(
            spotIndex,
            true, // isBuy
            spotPrice + ((spotPrice * 50) / 10000), // 0.5% slippage
            spotSizeInAsset,
            false, // reduceOnly
            3, // IOC
            uint128(block.timestamp << 32) + 10
        );

        currentSpotPosition.isLong = true;
        currentSpotPosition.size = spotSizeInAsset;
        currentSpotPosition.entryPrice = spotPrice;

        // Place perp short order
        // USDC: 6 decimals on EVM, 8 decimals in Core
        uint64 perpSizeCoreAmount = uint64(perpAmount) * 100;
        uint64 perpSizeInAsset = uint64(
            (uint256(perpSizeCoreAmount) * 1e6) / perpPrice
        );

        CoreWriterLib.placeLimitOrder(
            perpIndex,
            false, // isBuy (short)
            perpPrice - ((perpPrice * 50) / 10000), // 0.5% slippage
            perpSizeInAsset,
            false, // reduceOnly
            3, // IOC
            uint128(block.timestamp << 32) + 11
        );

        currentPerpPosition.isLong = false;
        currentPerpPosition.size = perpSizeInAsset;
        currentPerpPosition.entryPrice = perpPrice;
    }

    /**
     * @notice Bridges all funds back to vault
     */
    function _bridgeBackToVault() internal {
        // Query actual balances
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(this));
        PrecompileLib.SpotBalance memory spotBalance = PrecompileLib
            .spotBalance(address(this), USDC_TOKEN_ID);

        // Transfer funds back from perp to spot (if any perp margin)
        if (marginSummary.accountValue > 0) {
            uint64 perpUsdAmount = uint64(marginSummary.accountValue);
            CoreWriterLib.transferUsdClass(perpUsdAmount, false); // from perp to spot
        }

        // First swap any USDC back to USDT0
        if (spotBalance.total > 0) {
            // Buy USDT0 with USDC
            CoreWriterLib.placeLimitOrder(
                usdt0SpotIndex(),
                true, // buy USDT0
                PrecompileLib.spotPx(usdt0SpotIndex()) + 10, // slight slippage
                spotBalance.total,
                false,
                3, // IOC
                uint128(block.timestamp << 32) + 100
            );

            // Get USDT0 balance and bridge back
            PrecompileLib.SpotBalance memory usdt0Balance = PrecompileLib
                .spotBalance(address(this), usdt0TokenId());
            if (usdt0Balance.total > 0) {
                CoreWriterLib.bridgeToEvm(
                    usdt0TokenId(),
                    usdt0Balance.total,
                    false
                );
            }
        }

        // Transfer all USDT0 from Manager back to Vault
        uint256 managerBalance = usdt0.balanceOf(address(this));
        if (managerBalance > 0) {
            usdt0.safeTransfer(address(vault), managerBalance);
        }
    }

    //============================== ADMIN FUNCTIONS ===============================

    /**
     * @notice Updates the curator address
     */
    function updateCurator(address _curator) external requiresAuth {
        curator = _curator;
        emit CuratorUpdated(_curator);
    }

    /**
     * @notice Updates maximum allowed slippage
     */
    function updateMaxSlippage(uint16 _maxSlippageBps) external requiresAuth {
        maxSlippageBps = _maxSlippageBps;
        emit MaxSlippageUpdated(_maxSlippageBps);
    }

    /**
     * @notice Pauses allocations and rebalancing
     */
    function pause() external requiresAuth {
        isPaused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses allocations and rebalancing
     */
    function unpause() external requiresAuth {
        isPaused = false;
        emit Unpaused();
    }

    //============================== VIEW FUNCTIONS ===============================

    /**
     * @notice Returns current position details
     */
    function getPositions()
        external
        view
        returns (Position memory spot, Position memory perp)
    {
        return (currentSpotPosition, currentPerpPosition);
    }

    /**
     * @notice Returns whether positions are currently open
     */
    function hasOpenPositions() external view returns (bool) {
        return currentSpotPosition.size > 0 || currentPerpPosition.size > 0;
    }

    /**
     * @notice Estimates the current value of all positions
     */
    function estimatePositionValue() external view returns (uint256) {
        // Return 0 if no positions allocated
        if (totalAllocated == 0) {
            return 0;
        }

        uint256 totalValue = 0;

        // Add spot position value using real price
        if (currentSpotPosition.size > 0) {
            uint64 currentSpotPrice = PrecompileLib.spotPx(
                uint64(currentSpotPosition.index)
            );
            // size is in asset units (Core decimals), price is in Core decimals
            // Calculate value in Core decimals then convert to EVM
            uint64 spotValueCore = uint64((uint256(currentSpotPosition.size) * uint256(currentSpotPrice)) / 1e8);
            totalValue += HLConversions.weiToEvm(USDC_TOKEN_ID, spotValueCore);
        }

        // Add perp position value (initial margin + P&L)
        if (currentPerpPosition.size > 0) {
            // Start with initial allocated amount for perp
            totalValue += (totalAllocated * PERP_ALLOCATION_BPS) / 10000;

            uint64 currentPerpPrice = PrecompileLib.markPx(
                currentPerpPosition.index
            );
            // For short position, calculate the P&L
            // Both price and size are in 8 decimal format
            if (currentPerpPosition.entryPrice > currentPerpPrice) {
                // Profit from short
                uint256 priceDiff = currentPerpPosition.entryPrice - currentPerpPrice;
                uint256 perpProfit = (priceDiff * currentPerpPosition.size) / 1e10;
                totalValue += perpProfit;
            } else if (currentPerpPrice > currentPerpPosition.entryPrice) {
                // Loss from short
                uint256 priceDiff = currentPerpPrice - currentPerpPosition.entryPrice;
                uint256 perpLoss = (priceDiff * currentPerpPosition.size) / 1e10;
                // Subtract loss but ensure we don't go negative
                if (perpLoss < totalValue) {
                    totalValue -= perpLoss;
                } else {
                    totalValue = 0;
                }
            }
        }

        // Add margin in perp account (convert from Core to EVM decimals)
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(this));
        if (marginSummary.accountValue > 0) {
            totalValue += HLConversions.weiToEvm(USDC_TOKEN_ID, uint64(marginSummary.accountValue));
        }

        return totalValue;
    }
}
