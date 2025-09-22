// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "@solmate/utils/FixedPointMathLib.sol";
import { ReentrancyGuard } from "@solmate/utils/ReentrancyGuard.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibCrestStorage } from "../libraries/LibCrestStorage.sol";
import { PrecompileLib } from "@hyper-evm-lib/src/PrecompileLib.sol";
import { HLConstants } from "@hyper-evm-lib/src/common/HLConstants.sol";
import { HLConversions } from "@hyper-evm-lib/src/common/HLConversions.sol";
import { CoreWriterLib } from "@hyper-evm-lib/src/CoreWriterLib.sol";

contract ManagerFacet is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // ========================================= CONSTANTS =========================================

    uint64 public constant USDC_TOKEN_ID = 0;
    uint256 public constant TESTNET_CHAINID = 998;
    uint16 public constant MARGIN_ALLOCATION_BPS = 1000; // 10%
    uint16 public constant PERP_ALLOCATION_BPS = 4500; // 45%
    uint16 public constant SPOT_ALLOCATION_BPS = 4500; // 45%

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
    event DebugLogAmount(uint256 balance);

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
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        if (cs.isManagerPaused) revert CrestManager__Paused();
        _;
    }

    modifier onlyCurator() {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        if (
            msg.sender != cs.curator && msg.sender != LibDiamond.contractOwner()
        ) revert CrestManager__Unauthorized();
        _;
    }

    modifier requiresAuth() {
        require(msg.sender == LibDiamond.contractOwner(), "UNAUTHORIZED");
        _;
    }

    //============================== HELPER FUNCTIONS ===============================

    function usdt0TokenId() internal view returns (uint64) {
        return block.chainid == TESTNET_CHAINID ? 1 : 268;
    }

    function usdt0SpotIndex() internal view returns (uint32) {
        return block.chainid == TESTNET_CHAINID ? 0 : 166;
    }

    //============================== ALLOCATION FUNCTIONS ===============================

    function allocate__bridgeToCore()
        public
        onlyCurator
        whenNotPaused
        nonReentrant
    {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        // Get available USDT0 balance
        uint256 availableUsdt0 = cs.usdt0.balanceOf(address(this));

        // Check if we need to withdraw from Hyperdrive
        uint256 hyperdriveValue = IVaultFacet(address(this))
            .getHyperdriveValue();
        if (hyperdriveValue > 0) {
            IVaultFacet(address(this)).withdrawFromHyperdrive(
                type(uint256).max
            );
            availableUsdt0 = cs.usdt0.balanceOf(address(this));
        }

        // Bridge USDT0 to Hyperliquid core
        CoreWriterLib.bridgeToCore(address(cs.usdt0), availableUsdt0);

        uint64 usdt0CoreAmount = PrecompileLib
            .spotBalance(address(this), usdt0TokenId())
            .total;
        emit DebugLogAmount(usdt0CoreAmount);
    }

    function allocate__swapToUSDC()
        public
        onlyCurator
        whenNotPaused
        nonReentrant
    {
        uint64 usdt0CoreAmount = PrecompileLib
            .spotBalance(address(this), usdt0TokenId())
            .total;
        emit DebugLogAmount(usdt0CoreAmount);

        uint64 sz = usdt0CoreAmount * 10 ** 3;

        CoreWriterLib.placeLimitOrder(
            uint32(usdt0SpotIndex() + 10000),
            false,
            0,
            sz,
            false,
            HLConstants.LIMIT_ORDER_TIF_IOC,
            uint128(block.timestamp << 32)
        );
    }

    function allocatePositions(
        uint32 spotIndex,
        uint32 perpIndex
    ) external onlyCurator whenNotPaused {
        _openPositions(spotIndex, perpIndex);
    }

    function rebalancePositions(
        uint32 newSpotIndex,
        uint32 newPerpIndex
    ) external onlyCurator whenNotPaused {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        if (
            cs.currentSpotPosition.index == 0 &&
            cs.currentPerpPosition.index == 0
        ) {
            revert CrestManager__NoPositionToClose();
        }

        uint32 oldSpotIndex = cs.currentSpotPosition.index;
        uint32 oldPerpIndex = cs.currentPerpPosition.index;

        if (
            cs.currentSpotPosition.size > 0 || cs.currentPerpPosition.size > 0
        ) {
            _closePositionsOnly();
        }

        _openPositions(newSpotIndex, newPerpIndex);

        // Update vault state through VaultFacet
        IVaultFacet(address(this)).rebalance(newSpotIndex, newPerpIndex);

        emit Rebalanced(oldSpotIndex, oldPerpIndex, newSpotIndex, newPerpIndex);
    }

    function exit() external onlyCurator whenNotPaused {
        _closePositionsOnly();
        _bridgeBackToVault();

        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.totalAllocated = 0;
    }

    function _closePositionsOnly() internal {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        // Close spot position
        if (cs.currentSpotPosition.size > 0) {
            uint64 spotBid = _getSpotBidPrice(cs.currentSpotPosition.index);

            CoreWriterLib.placeLimitOrder(
                cs.currentSpotPosition.index,
                false,
                spotBid - ((spotBid * 100) / 10000),
                cs.currentSpotPosition.size,
                true,
                HLConstants.LIMIT_ORDER_TIF_IOC,
                uint128(block.timestamp + 2)
            );

            uint64 currentSpotPrice = PrecompileLib.spotPx(
                uint64(cs.currentSpotPosition.index)
            );
            int256 spotPnL;
            if (currentSpotPrice >= cs.currentSpotPosition.entryPrice) {
                spotPnL =
                    (int256(
                        uint256(
                            currentSpotPrice - cs.currentSpotPosition.entryPrice
                        )
                    ) * int256(uint256(cs.currentSpotPosition.size))) / 1e8;
            } else {
                spotPnL =
                    (-int256(
                        uint256(
                            cs.currentSpotPosition.entryPrice - currentSpotPrice
                        )
                    ) * int256(uint256(cs.currentSpotPosition.size))) / 1e8;
            }

            emit PositionClosed(
                true,
                cs.currentSpotPosition.index,
                uint256(spotPnL > 0 ? spotPnL : -spotPnL)
            );

            cs.currentSpotPosition.size = 0;
            cs.currentSpotPosition.entryPrice = 0;
        }

        // Close perp position
        if (cs.currentPerpPosition.size > 0) {
            uint64 perpAsk = _getPerpAskPrice(cs.currentPerpPosition.index);

            CoreWriterLib.placeLimitOrder(
                cs.currentPerpPosition.index,
                true,
                perpAsk + ((perpAsk * 100) / 10000),
                cs.currentPerpPosition.size,
                true,
                HLConstants.LIMIT_ORDER_TIF_IOC,
                uint128(block.timestamp + 3)
            );

            uint64 markPrice = PrecompileLib.markPx(
                cs.currentPerpPosition.index
            );
            int256 perpPnL;
            if (cs.currentPerpPosition.entryPrice >= markPrice) {
                perpPnL =
                    (int256(
                        uint256(cs.currentPerpPosition.entryPrice - markPrice)
                    ) * int256(uint256(cs.currentPerpPosition.size))) / 1e6;
            } else {
                perpPnL =
                    (-int256(
                        uint256(markPrice - cs.currentPerpPosition.entryPrice)
                    ) * int256(uint256(cs.currentPerpPosition.size))) / 1e6;
            }

            emit PositionClosed(
                false,
                cs.currentPerpPosition.index,
                uint256(perpPnL > 0 ? perpPnL : -perpPnL)
            );

            cs.currentPerpPosition.size = 0;
            cs.currentPerpPosition.entryPrice = 0;
        }

        // Move funds from perp back to spot account
        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(this));

        if (marginSummary.accountValue > 0) {
            uint64 perpUsdAmount = uint64(marginSummary.accountValue);
            CoreWriterLib.transferUsdClass(perpUsdAmount, false);
        }
    }

    function _openPositions(uint32 spotIndex, uint32 perpIndex) internal {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        cs.currentSpotPosition.index = spotIndex;
        cs.currentPerpPosition.index = perpIndex;
        cs.currentSpotPosition.timestamp = block.timestamp;
        cs.currentPerpPosition.timestamp = block.timestamp;

        PrecompileLib.SpotBalance memory usdcBalance = PrecompileLib
            .spotBalance(address(this), USDC_TOKEN_ID);

        if (usdcBalance.total == 0) return;

        uint256 totalUsdc = HLConversions.weiToEvm(
            USDC_TOKEN_ID,
            uint64(usdcBalance.total)
        );
        uint256 marginAmount = (totalUsdc * MARGIN_ALLOCATION_BPS) / 10000;
        uint256 spotAmount = (totalUsdc * SPOT_ALLOCATION_BPS) / 10000;
        uint256 perpAmount = (totalUsdc * PERP_ALLOCATION_BPS) / 10000;

        (uint64 spotPrice, uint64 perpPrice) = _getMarketPrices(
            spotIndex,
            perpIndex
        );

        // Transfer margin to perp account
        uint64 marginCoreAmount = HLConversions.evmToWei(
            USDC_TOKEN_ID,
            marginAmount
        );
        CoreWriterLib.transferUsdClass(marginCoreAmount, true);

        // Place spot buy order
        uint64 spotSizeCoreAmount = HLConversions.evmToWei(
            USDC_TOKEN_ID,
            spotAmount
        );
        uint64 spotSizeInAsset = uint64(
            (uint256(spotSizeCoreAmount) * 1e8) / spotPrice
        );

        CoreWriterLib.placeLimitOrder(
            spotIndex + 10000,
            true,
            spotPrice * 2,
            spotSizeInAsset,
            false,
            HLConstants.LIMIT_ORDER_TIF_IOC,
            uint128(block.timestamp << 32) + 10
        );

        cs.currentSpotPosition.isLong = true;
        cs.currentSpotPosition.size = spotSizeInAsset;
        cs.currentSpotPosition.entryPrice = spotPrice;

        // Place perp short order
        uint64 perpSizeCoreAmount = HLConversions.evmToWei(
            USDC_TOKEN_ID,
            perpAmount
        );
        uint64 perpSizeInAsset = uint64(
            (uint256(perpSizeCoreAmount) * 1e8) / perpPrice
        );

        CoreWriterLib.placeLimitOrder(
            perpIndex,
            false,
            perpPrice * 2,
            perpSizeInAsset,
            false,
            HLConstants.LIMIT_ORDER_TIF_IOC,
            uint128(block.timestamp << 32) + 11
        );

        cs.currentPerpPosition.isLong = false;
        cs.currentPerpPosition.size = perpSizeInAsset;
        cs.currentPerpPosition.entryPrice = perpPrice;
    }

    function _bridgeBackToVault() internal {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(this));
        PrecompileLib.SpotBalance memory spotBalance = PrecompileLib
            .spotBalance(address(this), USDC_TOKEN_ID);

        if (marginSummary.accountValue > 0) {
            uint64 perpUsdAmount = uint64(marginSummary.accountValue);
            CoreWriterLib.transferUsdClass(perpUsdAmount, false);
        }

        if (spotBalance.total > 0) {
            uint64 usdt0Ask = _getUsdt0AskPrice();
            CoreWriterLib.placeLimitOrder(
                usdt0SpotIndex(),
                true,
                usdt0Ask + ((usdt0Ask * 100) / 10000),
                spotBalance.total,
                false,
                HLConstants.LIMIT_ORDER_TIF_IOC,
                uint128(block.timestamp << 32) + 100
            );

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

        // Transfer all USDT0 back to Diamond
        uint256 managerBalance = cs.usdt0.balanceOf(address(this));
        if (managerBalance > 0) {
            cs.usdt0.safeTransfer(address(this), managerBalance);
        }
    }

    //============================== ADMIN FUNCTIONS ===============================

    function updateCurator(address _curator) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.curator = _curator;
        emit CuratorUpdated(_curator);
    }

    function updateMaxSlippage(uint16 _maxSlippageBps) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.maxSlippageBps = _maxSlippageBps;
        emit MaxSlippageUpdated(_maxSlippageBps);
    }

    function pauseManager() external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.isManagerPaused = true;
        emit Paused();
    }

    function unpauseManager() external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.isManagerPaused = false;
        emit Unpaused();
    }

    //============================== VIEW FUNCTIONS ===============================

    function getPositions()
        external
        view
        returns (
            LibCrestStorage.Position memory spot,
            LibCrestStorage.Position memory perp
        )
    {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        spot = cs.currentSpotPosition;
        perp = cs.currentPerpPosition;

        if (spot.index > 0) {
            PrecompileLib.SpotInfo memory spotInfo = PrecompileLib.spotInfo(
                spot.index
            );
            uint64 tokenId = spotInfo.tokens[0];
            PrecompileLib.SpotBalance memory actualBalance = PrecompileLib
                .spotBalance(address(this), tokenId);
            spot.size = actualBalance.total;

            if (actualBalance.total > 0 && cs.totalAllocated > 0) {
                uint256 spotAmount = (cs.totalAllocated * SPOT_ALLOCATION_BPS) /
                    10000;
                uint64 spotAmountCore = uint64(spotAmount) * 100;
                spot.entryPrice = uint64(
                    (uint256(spotAmountCore) * 1e8) / actualBalance.total
                );
            }
        }

        if (perp.index > 0) {
            PrecompileLib.Position memory perpPos = PrecompileLib.position(
                address(this),
                uint16(perp.index)
            );
            if (perpPos.szi != 0) {
                uint64 absSize = uint64(-perpPos.szi);
                perp.size = absSize;
                perp.entryPrice = uint64(
                    (perpPos.entryNtl * 1e6) / uint256(absSize)
                );
            }
        }

        return (spot, perp);
    }

    function hasOpenPositions() external view returns (bool) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        return
            cs.currentSpotPosition.size > 0 || cs.currentPerpPosition.size > 0;
    }

    function estimatePositionValue() external view returns (uint256) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        if (cs.totalAllocated == 0) {
            return 0;
        }

        uint256 totalValue = 0;

        if (cs.currentSpotPosition.index > 0) {
            PrecompileLib.SpotInfo memory spotInfo = PrecompileLib.spotInfo(
                uint64(cs.currentSpotPosition.index)
            );
            uint64 tokenId = spotInfo.tokens[0];

            PrecompileLib.SpotBalance memory spotBal = PrecompileLib
                .spotBalance(address(this), tokenId);

            if (spotBal.total > 0) {
                uint64 currentSpotPrice = _getSpotMidPrice(
                    cs.currentSpotPosition.index
                );
                uint64 spotValueCore = uint64(
                    (uint256(spotBal.total) * uint256(currentSpotPrice)) / 1e8
                );
                totalValue += HLConversions.weiToEvm(
                    USDC_TOKEN_ID,
                    spotValueCore
                );
            }
        }

        if (cs.currentPerpPosition.index > 0) {
            PrecompileLib.Position memory perpPos = PrecompileLib.position(
                address(this),
                uint16(cs.currentPerpPosition.index)
            );

            if (perpPos.szi != 0) {
                uint64 currentPerpPrice = _getPerpMidPrice(
                    cs.currentPerpPosition.index
                );

                uint256 absSize = perpPos.szi < 0
                    ? uint256(uint64(-perpPos.szi))
                    : uint256(uint64(perpPos.szi));

                if (perpPos.szi < 0) {
                    uint256 currentNtl = (absSize * currentPerpPrice) / 1e8;
                    if (perpPos.entryNtl > currentNtl) {
                        uint256 profit = perpPos.entryNtl - currentNtl;
                        totalValue += HLConversions.weiToEvm(
                            USDC_TOKEN_ID,
                            uint64(profit)
                        );
                    } else {
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

        PrecompileLib.AccountMarginSummary memory marginSummary = PrecompileLib
            .accountMarginSummary(0, address(this));
        if (marginSummary.accountValue > 0) {
            totalValue += HLConversions.weiToEvm(
                USDC_TOKEN_ID,
                uint64(marginSummary.accountValue)
            );
        }

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

    // Helper functions for price retrieval
    function _getMarketPrices(
        uint32 spotIndex,
        uint32 perpIndex
    ) internal view virtual returns (uint64 spotPrice, uint64 perpPrice) {
        PrecompileLib.Bbo memory spotBbo = PrecompileLib.bbo(
            uint64(spotIndex) + 10000
        );
        PrecompileLib.Bbo memory perpBbo = PrecompileLib.bbo(uint64(perpIndex));
        spotPrice = spotBbo.ask;
        perpPrice = perpBbo.bid;
    }

    function _getUsdt0AskPrice() internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory usdt0Bbo = PrecompileLib.bbo(
            uint64(usdt0SpotIndex()) + 10000
        );
        return HLConversions.weiToSz(uint64(usdt0SpotIndex()), usdt0Bbo.ask);
    }

    function _getSpotBidPrice(
        uint32 spotIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory spotBbo = PrecompileLib.bbo(
            uint64(spotIndex) + 10000
        );
        return spotBbo.bid * 100;
    }

    function _getPerpAskPrice(
        uint32 perpIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory perpBbo = PrecompileLib.bbo(uint64(perpIndex));
        return perpBbo.ask * 100;
    }

    function _getSpotMidPrice(
        uint32 spotIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory spotBbo = PrecompileLib.bbo(
            uint64(spotIndex) + 10000
        );
        return ((spotBbo.bid + spotBbo.ask) / 2) * 100;
    }

    function _getPerpMidPrice(
        uint32 perpIndex
    ) internal view virtual returns (uint64) {
        PrecompileLib.Bbo memory perpBbo = PrecompileLib.bbo(uint64(perpIndex));
        return ((perpBbo.bid + perpBbo.ask) / 2) * 100;
    }

    // Getters
    function curator() external view returns (address) {
        return LibCrestStorage.crestStorage().curator;
    }

    function maxSlippageBps() external view returns (uint16) {
        return LibCrestStorage.crestStorage().maxSlippageBps;
    }

    function totalAllocated() external view returns (uint256) {
        return LibCrestStorage.crestStorage().totalAllocated;
    }

    function isManagerPaused() external view returns (bool) {
        return LibCrestStorage.crestStorage().isManagerPaused;
    }
}

// Interface for cross-facet calls
interface IVaultFacet {
    function rebalance(uint32 newSpotIndex, uint32 newPerpIndex) external;
    function getHyperdriveValue() external view returns (uint256);
    function withdrawFromHyperdrive(uint256 amount) external returns (uint256);
}
