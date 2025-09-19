// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {Auth, Authority} from "@solmate/auth/Auth.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";
import {CrestVault} from "./CrestVault.sol";
import {HyperliquidLib, HLConstants, HLConversions} from "./libraries/HyperliquidLib.sol";
import {PrecompileLib} from "@hyper-evm-lib/src/PrecompileLib.sol";

contract CrestManager is Auth, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using HyperliquidLib for *;

    // ========================================= CONSTANTS =========================================

    /**
     * @notice USDC token ID on Hyperliquid
     */
    uint64 public constant USDC_TOKEN_ID = 0;

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
     * @notice The USDC token contract
     */
    ERC20 public immutable usdc;

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

    event Allocated(uint32 spotIndex, uint32 perpIndex, uint256 totalAmount, uint256 marginAmount, uint256 spotAmount, uint256 perpAmount);
    event Rebalanced(uint32 oldSpotIndex, uint32 oldPerpIndex, uint32 newSpotIndex, uint32 newPerpIndex);
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
        if (msg.sender != curator && msg.sender != owner) revert CrestManager__Unauthorized();
        _;
    }

    //============================== CONSTRUCTOR ===============================

    constructor(
        address payable _vault,
        address _usdc,
        address _owner,
        address _curator
    ) Auth(_owner, Authority(address(0))) {
        vault = CrestVault(_vault);
        usdc = ERC20(_usdc);
        curator = _curator;
    }

    //============================== ALLOCATION FUNCTIONS ===============================

    /**
     * @notice Allocates vault funds to Hyperliquid positions
     * @param spotIndex The spot market index to buy
     * @param perpIndex The perp market index to short
     */
    function allocate(uint32 spotIndex, uint32 perpIndex)
        external
        onlyCurator
        whenNotPaused
        nonReentrant
    {
        // Check if positions are already open
        if (currentSpotPosition.size > 0 || currentPerpPosition.size > 0) {
            revert CrestManager__PositionAlreadyOpen();
        }

        // Get available USDC balance
        uint256 availableUsdc = usdc.balanceOf(address(vault));
        if (availableUsdc == 0) revert CrestManager__InsufficientBalance();

        // Calculate allocations
        uint256 marginAmount = (availableUsdc * MARGIN_ALLOCATION_BPS) / 10000;
        uint256 spotAmount = (availableUsdc * SPOT_ALLOCATION_BPS) / 10000;
        uint256 perpAmount = (availableUsdc * PERP_ALLOCATION_BPS) / 10000;

        // Get current prices from Hyperliquid precompiles
        uint64 spotPrice = PrecompileLib.spotPx(uint64(spotIndex));
        uint64 perpPrice = PrecompileLib.markPx(perpIndex);

        // Transfer USDC from vault to this contract first
        bytes memory transferData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            address(this),
            marginAmount + spotAmount + perpAmount
        );
        vault.manage(address(usdc), transferData, 0);

        // Bridge USDC to Hyperliquid core
        HyperliquidLib.bridgeToCore(address(usdc), marginAmount + spotAmount + perpAmount);

        // Transfer margin to perp account
        uint64 marginCoreAmount = HLConversions.evmToWei(USDC_TOKEN_ID, marginAmount);
        // Transfer margin to perp account
        HyperliquidLib.transferUsdClass(HLConversions.weiToPerp(marginCoreAmount), true);

        // Place spot buy order
        uint64 spotSizeCoreAmount = HLConversions.evmToWei(USDC_TOKEN_ID, spotAmount);
        uint64 spotSizeInAsset = uint64((uint256(spotSizeCoreAmount) * 1e8) / spotPrice);

        // Place spot buy order
        HyperliquidLib.placeLimitOrder(
            spotIndex,
            true, // isBuy
            uint64(spotPrice),
            spotSizeInAsset,
            false, // reduceOnly
            2, // GTC
            uint128(block.timestamp) // cloid
        );

        // Place perp short order
        uint64 perpSizeCoreAmount = HLConversions.evmToWei(USDC_TOKEN_ID, perpAmount);
        uint64 perpSizeInAsset = uint64((uint256(perpSizeCoreAmount) * 1e6) / perpPrice);

        // Place perp short order
        HyperliquidLib.placeLimitOrder(
            perpIndex,
            false, // isBuy (short)
            uint64(perpPrice),
            perpSizeInAsset,
            false, // reduceOnly
            2, // GTC
            uint128(block.timestamp + 1) // cloid
        );

        // Update positions
        currentSpotPosition = Position({
            index: spotIndex,
            isLong: true,
            size: spotSizeInAsset,
            entryPrice: uint64(spotPrice),
            timestamp: block.timestamp
        });

        currentPerpPosition = Position({
            index: perpIndex,
            isLong: false,
            size: perpSizeInAsset,
            entryPrice: uint64(perpPrice),
            timestamp: block.timestamp
        });

        totalAllocated = marginAmount + spotAmount + perpAmount;

        // Update vault indexes
        vault.allocate(spotIndex, perpIndex);

        emit Allocated(spotIndex, perpIndex, totalAllocated, marginAmount, spotAmount, perpAmount);
    }

    /**
     * @notice Rebalances the vault to new positions
     * @param newSpotIndex The new spot market index
     * @param newPerpIndex The new perp market index
     */
    function rebalance(uint32 newSpotIndex, uint32 newPerpIndex)
        external
        onlyCurator
        whenNotPaused
        nonReentrant
    {
        // Check if there are any positions to rebalance
        if (currentSpotPosition.index == 0 && currentPerpPosition.index == 0) {
            revert CrestManager__NoPositionToClose();
        }

        uint32 oldSpotIndex = currentSpotPosition.index;
        uint32 oldPerpIndex = currentPerpPosition.index;

        // Close existing positions if they have size
        if (currentSpotPosition.size > 0 || currentPerpPosition.size > 0) {
            _closeAllPositions();
        }

        // Update vault state
        vault.rebalance(newSpotIndex, newPerpIndex);

        // Update manager's position tracking to new indexes
        currentSpotPosition.index = newSpotIndex;
        currentPerpPosition.index = newPerpIndex;
        currentSpotPosition.size = 0; // Will be set when orders fill
        currentPerpPosition.size = 0; // Will be set when orders fill

        emit Rebalanced(
            oldSpotIndex,
            oldPerpIndex,
            newSpotIndex,
            newPerpIndex
        );
    }

    /**
     * @notice Closes all positions and withdraws funds back to vault
     */
    function closeAllPositions() external onlyCurator whenNotPaused nonReentrant {
        _closeAllPositions();
    }

    function _closeAllPositions() internal {
        // Close spot position
        if (currentSpotPosition.size > 0) {
            // Get current spot price from precompile
            uint64 currentSpotPrice = PrecompileLib.spotPx(uint64(currentSpotPosition.index));

            HyperliquidLib.placeLimitOrder(
                currentSpotPosition.index,
                false, // isBuy (sell to close)
                currentSpotPrice,
                currentSpotPosition.size,
                true, // reduceOnly
                3, // IOC
                uint128(block.timestamp + 2) // cloid
            );

            // Calculate PnL
            int256 spotPnL;
            if (currentSpotPrice >= currentSpotPosition.entryPrice) {
                spotPnL = int256(uint256(currentSpotPrice - currentSpotPosition.entryPrice)) * int256(uint256(currentSpotPosition.size)) / 1e8;
            } else {
                spotPnL = -int256(uint256(currentSpotPosition.entryPrice - currentSpotPrice)) * int256(uint256(currentSpotPosition.size)) / 1e8;
            }

            emit PositionClosed(true, currentSpotPosition.index, uint256(spotPnL > 0 ? spotPnL : -spotPnL));

            delete currentSpotPosition;
        }

        // Close perp position
        if (currentPerpPosition.size > 0) {
            // Get current perp mark price from precompile
            uint64 currentPerpPrice = PrecompileLib.markPx(currentPerpPosition.index);

            HyperliquidLib.placeLimitOrder(
                currentPerpPosition.index,
                true, // isBuy (buy to close short)
                currentPerpPrice,
                currentPerpPosition.size,
                true, // reduceOnly
                3, // IOC
                uint128(block.timestamp + 3) // cloid
            );

            // Calculate PnL (inverted for short)
            int256 perpPnL;
            if (currentPerpPosition.entryPrice >= currentPerpPrice) {
                perpPnL = int256(uint256(currentPerpPosition.entryPrice - currentPerpPrice)) * int256(uint256(currentPerpPosition.size)) / 1e6;
            } else {
                perpPnL = -int256(uint256(currentPerpPrice - currentPerpPosition.entryPrice)) * int256(uint256(currentPerpPosition.size)) / 1e6;
            }

            emit PositionClosed(false, currentPerpPosition.index, uint256(perpPnL > 0 ? perpPnL : -perpPnL));

            delete currentPerpPosition;
        }

        // Query actual balances to bridge back
        // Use perpDexIndex 0 for cross-margin account
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib.accountMarginSummary(0, address(this));
        PrecompileLib.SpotBalance memory spotBalance = PrecompileLib.spotBalance(address(this), USDC_TOKEN_ID);

        // Transfer funds back from perp to spot (if any perp margin)
        if (marginSummary.accountValue > 0) {
            uint64 perpUsdAmount = uint64(marginSummary.accountValue);
            HyperliquidLib.transferUsdClass(perpUsdAmount, false); // from perp to spot
        }

        // Bridge all USDC back to EVM
        if (spotBalance.total > 0) {
            HyperliquidLib.bridgeToEvm(USDC_TOKEN_ID, spotBalance.total, false);
        }

        totalAllocated = 0;
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
    function getPositions() external view returns (Position memory spot, Position memory perp) {
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
        uint256 totalValue = 0;

        // Add spot position value using real price
        if (currentSpotPosition.size > 0) {
            uint64 currentSpotPrice = PrecompileLib.spotPx(uint64(currentSpotPosition.index));
            totalValue += (currentSpotPosition.size * currentSpotPrice) / 1e8;
        }

        // Add perp position value using real mark price
        if (currentPerpPosition.size > 0) {
            uint64 currentPerpPrice = PrecompileLib.markPx(currentPerpPosition.index);
            // For short position, calculate the P&L
            int256 perpPnL = int256(uint256(currentPerpPosition.entryPrice - currentPerpPrice)) * int256(uint256(currentPerpPosition.size)) / 1e6;
            if (perpPnL > 0) {
                totalValue += uint256(perpPnL);
            }
        }

        // Add any unallocated USDC in the vault
        uint256 vaultBalance = usdc.balanceOf(address(vault));
        totalValue += vaultBalance;

        // Add margin in perp account
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib.accountMarginSummary(0, address(this));
        if (marginSummary.accountValue > 0) {
            totalValue += uint256(uint64(marginSummary.accountValue));
        }

        return totalValue;
    }
}