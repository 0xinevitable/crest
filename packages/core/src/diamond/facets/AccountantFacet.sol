// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { FixedPointMathLib } from "@solmate/utils/FixedPointMathLib.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibCrestStorage } from "../libraries/LibCrestStorage.sol";
import { IVaultFacet } from "../interfaces/IVaultFacet.sol";

contract AccountantFacet {
    using FixedPointMathLib for uint256;

    //============================== EVENTS ===============================

    event RateUpdated(
        uint96 oldRate,
        uint96 newRate,
        uint256 platformFees,
        uint256 performanceFees
    );
    event FeesUpdated(uint16 platformFeeBps, uint16 performanceFeeBps);
    event FeeRecipientUpdated(address indexed recipient);
    event FeesCollected(
        address indexed recipient,
        uint256 platformFees,
        uint256 performanceFees
    );
    event Paused();
    event Unpaused();

    //============================== ERRORS ===============================

    error CrestAccountant__Paused();
    error CrestAccountant__NoFeeRecipient();
    error CrestAccountant__InvalidFee();

    //============================== MODIFIERS ===============================

    modifier whenNotPaused() {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        if (cs.isAccountantPaused) revert CrestAccountant__Paused();
        _;
    }

    modifier requiresAuth() {
        require(msg.sender == LibDiamond.contractOwner(), "UNAUTHORIZED");
        _;
    }

    //============================== ADMIN FUNCTIONS ===============================

    function _updateFees() internal {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        uint256 totalSupply = ERC20(address(this)).totalSupply();
        if (totalSupply == 0) return;

        uint256 currentAssets = getTotalAssets();

        // Initialize lastTotalAssets on first call
        if (cs.lastTotalAssets == 0) {
            cs.lastTotalAssets = currentAssets;
            return;
        }

        // Skip if no profit
        if (currentAssets <= cs.lastTotalAssets) {
            cs.lastTotalAssets = currentAssets;
            return;
        }

        uint256 profit = currentAssets - cs.lastTotalAssets;

        // Calculate current rate
        uint96 currentRate = uint96((currentAssets * 1e6) / totalSupply);

        // Platform fee on all profit
        uint256 platformFee = (profit * cs.platformFeeBps) / 10000;

        // Performance fee only on profit above high water mark
        uint256 performanceFee = 0;
        if (currentRate > cs.highWaterMark) {
            uint256 outperformance = currentAssets -
                ((uint256(cs.highWaterMark) * totalSupply) / 1e6);
            performanceFee = (outperformance * cs.performanceFeeBps) / 10000;
            cs.highWaterMark = currentRate;
        }

        cs.accumulatedPlatformFees += platformFee;
        cs.accumulatedPerformanceFees += performanceFee;
        cs.lastTotalAssets = currentAssets;

        emit RateUpdated(0, currentRate, platformFee, performanceFee);
    }

    function collectFees() external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        if (cs.feeRecipient == address(0))
            revert CrestAccountant__NoFeeRecipient();

        uint256 platformFees = cs.accumulatedPlatformFees;
        uint256 performanceFees = cs.accumulatedPerformanceFees;

        cs.accumulatedPlatformFees = 0;
        cs.accumulatedPerformanceFees = 0;

        uint256 totalFees = platformFees + performanceFees;
        if (totalFees > 0) {
            // Mint fee shares to recipient through VaultFacet
            uint256 feeShares = (totalFees * 1e6) / getRate();
            IVaultFacet(address(this)).enter(
                address(this),
                ERC20(address(0)),
                0,
                cs.feeRecipient,
                feeShares
            );
        }

        emit FeesCollected(cs.feeRecipient, platformFees, performanceFees);
    }

    function updateFees(
        uint16 _platformFeeBps,
        uint16 _performanceFeeBps
    ) external requiresAuth {
        if (_platformFeeBps > 500) revert CrestAccountant__InvalidFee(); // Max 5%
        if (_performanceFeeBps > 3000) revert CrestAccountant__InvalidFee(); // Max 30%

        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.platformFeeBps = _platformFeeBps;
        cs.performanceFeeBps = _performanceFeeBps;

        emit FeesUpdated(_platformFeeBps, _performanceFeeBps);
    }

    function updateFeeRecipient(address _feeRecipient) external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    function pauseAccountant() external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.isAccountantPaused = true;
        emit Paused();
    }

    function unpauseAccountant() external requiresAuth {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();
        cs.isAccountantPaused = false;
        emit Unpaused();
    }

    //============================== VIEW FUNCTIONS ===============================

    function getTotalAssets() public view returns (uint256) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        // Get USDT0 balance in diamond
        uint256 vaultBalance = cs.usdt0.balanceOf(address(this));

        // Add Hyperdrive value
        uint256 hyperdriveValue = IVaultFacet(address(this))
            .getHyperdriveValue();

        // Add Core position values from Manager
        uint256 corePositionValue = IManagerFacet(address(this))
            .estimatePositionValue();

        return vaultBalance + hyperdriveValue + corePositionValue;
    }

    function getRate() public view returns (uint256) {
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        uint256 totalSupply = ERC20(address(this)).totalSupply();
        if (totalSupply == 0) return 1e6;

        uint256 totalAssets = getTotalAssets();

        // Deduct accumulated fees from assets
        uint256 totalFees = cs.accumulatedPlatformFees +
            cs.accumulatedPerformanceFees;
        if (totalAssets > totalFees) {
            totalAssets -= totalFees;
        }

        return (totalAssets * 1e6) / totalSupply;
    }

    function updateAccountantFees() external whenNotPaused {
        _updateFees();
    }

    function exchangeRate() external view returns (uint256) {
        return getRate();
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 rate = getRate();
        if (rate == 0) return 0;
        return (assets * 1e6) / rate;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return (shares * getRate()) / 1e6;
    }

    // Getters
    function lastTotalAssets() external view returns (uint256) {
        return LibCrestStorage.crestStorage().lastTotalAssets;
    }

    function platformFeeBps() external view returns (uint16) {
        return LibCrestStorage.crestStorage().platformFeeBps;
    }

    function performanceFeeBps() external view returns (uint16) {
        return LibCrestStorage.crestStorage().performanceFeeBps;
    }

    function highWaterMark() external view returns (uint96) {
        return LibCrestStorage.crestStorage().highWaterMark;
    }

    function accumulatedPlatformFees() external view returns (uint256) {
        return LibCrestStorage.crestStorage().accumulatedPlatformFees;
    }

    function accumulatedPerformanceFees() external view returns (uint256) {
        return LibCrestStorage.crestStorage().accumulatedPerformanceFees;
    }

    function feeRecipient() external view returns (address) {
        return LibCrestStorage.crestStorage().feeRecipient;
    }

    function isAccountantPaused() external view returns (bool) {
        return LibCrestStorage.crestStorage().isAccountantPaused;
    }
}

interface IManagerFacet {
    function estimatePositionValue() external view returns (uint256);
}
