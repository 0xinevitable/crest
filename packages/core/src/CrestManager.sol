// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "@solmate/utils/FixedPointMathLib.sol";
import { Auth, Authority } from "@solmate/auth/Auth.sol";
import { ReentrancyGuard } from "@solmate/utils/ReentrancyGuard.sol";
import { CrestVault } from "./CrestVault.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";
import { HLConversions } from "@hyper-evm-lib/src/common/HLConversions.sol";
import { CoreWriterLib } from "@hyper-evm-lib/src/CoreWriterLib.sol";

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

        // Get available USDT0 balance (check vault balance -> IDLE is deposited to vault)
        uint256 availableUsdt0 = usdt0.balanceOf(address(vault));

        // Check if we need to withdraw from Hyperdrive
        uint256 hyperdriveValue = vault.getHyperdriveValue();
        if (hyperdriveValue > 0) {
            // Withdraw all from Hyperdrive for allocation
            vault.withdrawFromHyperdrive(type(uint256).max);
            // Update vault balance after withdrawal
            availableUsdt0 = usdt0.balanceOf(address(vault));
        }

        // Minimum 22 USDT0 needed to meet Core's minimum order requirements
        if (availableUsdt0 < 22e6) revert CrestManager__InsufficientBalance();

        // Calculate allocations
        uint256 marginAmount = (availableUsdt0 * MARGIN_ALLOCATION_BPS) / 10000;
        uint256 spotAmount = (availableUsdt0 * SPOT_ALLOCATION_BPS) / 10000;
        uint256 perpAmount = (availableUsdt0 * PERP_ALLOCATION_BPS) / 10000;

        // Get prices for calculations
        (uint64 spotPrice, uint64 perpPrice) = _getMarketPrices(
            spotIndex,
            perpIndex
        );

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
        {
            uint64 usdt0Bid = _getUsdt0BidPrice();
            CoreWriterLib.placeLimitOrder(
                usdt0SpotIndex(),
                false, // sell USDT0
                usdt0Bid - ((usdt0Bid * 100) / 10000), // sell at bid - 1% slippage
                usdt0CoreAmount,
                false, // not reduce only
                3, // IOC
                uint128(block.timestamp << 32) // unique cloid
            );
        }

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
            // Place spot buy order at ask price (for immediate fill)
            CoreWriterLib.placeLimitOrder(
                spotIndex,
                true, // isBuy
                spotPrice, // Already includes slippage
                uint64((uint256(uint64(spotAmount) * 100) * 1e8) / spotPrice), // size calculation inline
                false, // reduceOnly
                3, // IOC (Immediate or Cancel)
                uint128(block.timestamp) // cloid
            );

            // Update spot position
            currentSpotPosition.index = spotIndex;
            currentSpotPosition.isLong = true;
            currentSpotPosition.timestamp = block.timestamp;
        }

        // Place perp short order
        {
            // Place perp short order at bid price (for immediate fill)
            CoreWriterLib.placeLimitOrder(
                perpIndex,
                false, // isBuy (short)
                perpPrice, // Already includes slippage
                uint64((uint256(uint64(perpAmount) * 100) * 1e6) / perpPrice), // size calculation inline
                false, // reduceOnly
                3, // IOC (Immediate or Cancel)
                uint128(block.timestamp + 1) // cloid
            );

            // Update perp position
            currentPerpPosition.index = perpIndex;
            currentPerpPosition.isLong = false;
            currentPerpPosition.timestamp = block.timestamp;
        }

        totalAllocated = marginAmount + spotAmount + perpAmount;

        // Query and update actual positions after orders are filled
        _updatePositionsFromChain(spotIndex, perpIndex);

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
            // Get price for spot closing
            uint64 spotBid = _getSpotBidPrice(currentSpotPosition.index);

            // Sell with slippage for immediate execution
            CoreWriterLib.placeLimitOrder(
                currentSpotPosition.index,
                false, // isBuy (sell to close)
                spotBid - ((spotBid * 100) / 10000), // Sell at bid - 1% slippage
                currentSpotPosition.size,
                true, // reduceOnly
                3, // IOC
                uint128(block.timestamp + 2) // cloid
            );

            // Calculate PnL using spot price
            uint64 currentSpotPrice = PrecompileLib.spotPx(
                uint64(currentSpotPosition.index)
            );
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
            // Get price for perp closing
            uint64 perpAsk = _getPerpAskPrice(currentPerpPosition.index);

            // Buy to close short with slippage for immediate execution
            CoreWriterLib.placeLimitOrder(
                currentPerpPosition.index,
                true, // isBuy (buy to close short)
                perpAsk + ((perpAsk * 100) / 10000), // Buy at ask + 1% slippage
                currentPerpPosition.size,
                true, // reduceOnly
                3, // IOC
                uint128(block.timestamp + 3) // cloid
            );

            // Calculate PnL (inverted for short) using mid price
            uint64 markPrice = PrecompileLib.markPx(currentPerpPosition.index);
            int256 perpPnL;
            if (currentPerpPosition.entryPrice >= markPrice) {
                perpPnL =
                    (int256(
                        uint256(currentPerpPosition.entryPrice - markPrice)
                    ) * int256(uint256(currentPerpPosition.size))) / 1e6;
            } else {
                perpPnL =
                    (-int256(
                        uint256(markPrice - currentPerpPosition.entryPrice)
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
        uint256 totalUsdc = HLConversions.weiToEvm(
            USDC_TOKEN_ID,
            uint64(usdcBalance.total)
        );
        uint256 marginAmount = (totalUsdc * MARGIN_ALLOCATION_BPS) / 10000;
        uint256 spotAmount = (totalUsdc * SPOT_ALLOCATION_BPS) / 10000;
        uint256 perpAmount = (totalUsdc * PERP_ALLOCATION_BPS) / 10000;

        // Get prices for rebalance orders
        (uint64 spotPrice, uint64 perpPrice) = _getMarketPrices(
            spotIndex,
            perpIndex
        );

        // Transfer margin to perp account
        // Convert USDC from EVM decimals to Core decimals
        uint64 marginCoreAmount = HLConversions.evmToWei(
            USDC_TOKEN_ID,
            marginAmount
        );
        CoreWriterLib.transferUsdClass(marginCoreAmount, true);

        // Place spot buy order
        // Convert USDC from EVM decimals to Core decimals
        uint64 spotSizeCoreAmount = HLConversions.evmToWei(
            USDC_TOKEN_ID,
            spotAmount
        );
        // Use spot price for size calculation
        uint64 spotSizeInAsset = uint64(
            (uint256(spotSizeCoreAmount) * 1e8) / spotPrice
        );

        CoreWriterLib.placeLimitOrder(
            spotIndex,
            true, // isBuy
            spotPrice, // Already includes slippage
            spotSizeInAsset,
            false, // reduceOnly
            3, // IOC
            uint128(block.timestamp << 32) + 10
        );

        currentSpotPosition.isLong = true;
        currentSpotPosition.size = spotSizeInAsset;
        currentSpotPosition.entryPrice = spotPrice;

        // Place perp short order
        // Convert USDC from EVM decimals to Core decimals
        uint64 perpSizeCoreAmount = HLConversions.evmToWei(
            USDC_TOKEN_ID,
            perpAmount
        );
        // Use bid price for size calculation
        uint64 perpSizeInAsset = uint64(
            (uint256(perpSizeCoreAmount) * 1e8) / perpPrice
        );

        CoreWriterLib.placeLimitOrder(
            perpIndex,
            false, // isBuy (short)
            perpPrice, // Already includes slippage
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
            uint64 usdt0Ask = _getUsdt0AskPrice();
            CoreWriterLib.placeLimitOrder(
                usdt0SpotIndex(),
                true, // buy USDT0
                usdt0Ask + ((usdt0Ask * 100) / 10000), // buy at ask + 1% slippage
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

        // Query actual spot balance from precompile (for spot tokens we're holding)
        // For spot positions, we check the actual token balance (e.g., HYPE)
        if (currentSpotPosition.index > 0) {
            // Get the token ID from the spot market info
            PrecompileLib.SpotInfo memory spotInfo = PrecompileLib.spotInfo(
                uint64(currentSpotPosition.index)
            );
            uint64 tokenId = spotInfo.tokens[0]; // First token is the base asset (e.g., HYPE)

            // Get actual spot balance for the asset
            PrecompileLib.SpotBalance memory spotBal = PrecompileLib
                .spotBalance(address(this), tokenId);

            if (spotBal.total > 0) {
                uint64 currentSpotPrice = _getSpotMidPrice(
                    currentSpotPosition.index
                );
                // spotBal.total is in Core decimals (8), price is in Core decimals (8)
                // Result needs to be in USDT0 (6 decimals)
                uint64 spotValueCore = uint64(
                    (uint256(spotBal.total) * uint256(currentSpotPrice)) / 1e8
                );
                totalValue += HLConversions.weiToEvm(
                    USDC_TOKEN_ID,
                    spotValueCore
                );
            }
        }

        // Query actual perp position from precompile
        if (currentPerpPosition.index > 0) {
            PrecompileLib.Position memory perpPos = PrecompileLib.position(
                address(this),
                uint16(currentPerpPosition.index)
            );

            // szi is the signed size (negative for shorts)
            if (perpPos.szi != 0) {
                uint64 currentPerpPrice = _getPerpMidPrice(
                    currentPerpPosition.index
                );

                // Calculate notional value of position
                // szi is signed, negative for shorts
                uint256 absSize = perpPos.szi < 0
                    ? uint256(uint64(-perpPos.szi))
                    : uint256(uint64(perpPos.szi));

                // Calculate position value based on entry notional and current price
                // entryNtl is the entry notional value in Core decimals
                // For shorts, profit when price goes down
                if (perpPos.szi < 0) {
                    // Short position
                    // Calculate P&L for short
                    uint256 currentNtl = (absSize * currentPerpPrice) / 1e8;
                    if (perpPos.entryNtl > currentNtl) {
                        // Profit on short
                        uint256 profit = perpPos.entryNtl - currentNtl;
                        totalValue += HLConversions.weiToEvm(
                            USDC_TOKEN_ID,
                            uint64(profit)
                        );
                    } else {
                        // Loss on short
                        uint256 loss = currentNtl - perpPos.entryNtl;
                        uint256 lossEvm = HLConversions.weiToEvm(
                            USDC_TOKEN_ID,
                            uint64(loss)
                        );
                        if (lossEvm < totalValue) {
                            totalValue -= lossEvm;
                        } else {
                            totalValue = 0;
                        }
                    }
                }
            }
        }

        // Add margin in perp account (includes margin for positions + unrealized PnL)
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(this));
        if (marginSummary.accountValue > 0) {
            totalValue += HLConversions.weiToEvm(
                USDC_TOKEN_ID,
                uint64(marginSummary.accountValue)
            );
        }

        // Also check for any remaining USDC balance in spot account
        PrecompileLib.SpotBalance memory usdcBalance = PrecompileLib
            .spotBalance(address(this), USDC_TOKEN_ID);
        if (usdcBalance.total > 0) {
            totalValue += HLConversions.weiToEvm(
                USDC_TOKEN_ID,
                uint64(usdcBalance.total)
            );
        }

        return totalValue;
    }

    /**
     * @notice Updates position data from on-chain state
     */
    function _updatePositionsFromChain(
        uint32 spotIndex,
        uint32 perpIndex
    ) internal {
        // Update spot position from actual balance
        if (spotIndex > 0) {
            PrecompileLib.SpotInfo memory spotInfo = PrecompileLib.spotInfo(
                spotIndex
            );
            uint64 tokenId = spotInfo.tokens[0];
            PrecompileLib.SpotBalance memory actualBalance = PrecompileLib
                .spotBalance(address(this), tokenId);
            currentSpotPosition.size = actualBalance.total;

            // Calculate entry price from total allocated
            if (actualBalance.total > 0 && totalAllocated > 0) {
                uint256 spotAmount = (totalAllocated * SPOT_ALLOCATION_BPS) /
                    10000;
                uint64 spotAmountCore = uint64(spotAmount) * 100;
                currentSpotPosition.entryPrice = uint64(
                    (uint256(spotAmountCore) * 1e8) / actualBalance.total
                );
            }
        }

        // Update perp position from actual position
        if (perpIndex > 0) {
            PrecompileLib.Position memory perpPos = PrecompileLib.position(
                address(this),
                uint16(perpIndex)
            );
            if (perpPos.szi != 0 && perpPos.entryNtl > 0) {
                uint64 absSize = uint64(-perpPos.szi);
                currentPerpPosition.size = absSize;
                currentPerpPosition.entryPrice = uint64(
                    (perpPos.entryNtl * 1e6) / uint256(absSize)
                );
            }
        }
    }

    // Helper functions for price retrieval with BBO fallback
    function _getMarketPrices(
        uint32 spotIndex,
        uint32 perpIndex
    ) internal view virtual returns (uint64 spotPrice, uint64 perpPrice) {
        // For production, use BBO. Tests can override if needed.
        PrecompileLib.Bbo memory spotBbo = PrecompileLib.bbo(
            uint64(spotIndex) + 10000
        );
        PrecompileLib.Bbo memory perpBbo = PrecompileLib.bbo(uint64(perpIndex));

        spotPrice = spotBbo.ask; // Buy at ask
        perpPrice = perpBbo.bid; // Short at bid
    }

    function _getUsdt0BidPrice() internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory usdt0Bbo = PrecompileLib.bbo(
            uint64(usdt0SpotIndex()) + 10000
        );
        return usdt0Bbo.bid;
    }

    function _getUsdt0AskPrice() internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory usdt0Bbo = PrecompileLib.bbo(
            uint64(usdt0SpotIndex()) + 10000
        );
        return usdt0Bbo.ask;
    }

    function _getSpotBidPrice(
        uint32 spotIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory spotBbo = PrecompileLib.bbo(
            uint64(spotIndex) + 10000
        );
        return spotBbo.bid;
    }

    function _getPerpAskPrice(
        uint32 perpIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory perpBbo = PrecompileLib.bbo(uint64(perpIndex));
        return perpBbo.ask;
    }

    function _getSpotMidPrice(
        uint32 spotIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory spotBbo = PrecompileLib.bbo(
            uint64(spotIndex) + 10000
        );
        return (spotBbo.bid + spotBbo.ask) / 2;
    }

    function _getPerpMidPrice(
        uint32 perpIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory perpBbo = PrecompileLib.bbo(uint64(perpIndex));
        return (perpBbo.bid + perpBbo.ask) / 2;
    }
}
