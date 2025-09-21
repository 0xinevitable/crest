// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from '@solmate/tokens/ERC20.sol';
import { FixedPointMathLib } from '@solmate/utils/FixedPointMathLib.sol';
import { Auth, Authority } from '@solmate/auth/Auth.sol';
import { CrestVault } from './CrestVault.sol';
import { CrestManager } from './CrestManager.sol';

contract CrestAccountant is Auth {
    using FixedPointMathLib for uint256;

    // ========================================= STATE =========================================

    /**
     * @notice The CrestVault contract
     */
    CrestVault public immutable vault;

    /**
     * @notice The USDT0 token contract
     */
    ERC20 public immutable usdt0;

    /**
     * @notice The CrestManager contract
     */
    CrestManager public immutable manager;

    /**
     * @notice Last recorded total assets for fee calculation
     */
    uint256 public lastTotalAssets;

    /**
     * @notice Platform fee in basis points (100 = 1%)
     */
    uint16 public platformFeeBps = 100; // 1%

    /**
     * @notice Performance fee in basis points (100 = 1%)
     */
    uint16 public performanceFeeBps = 500; // 5%

    /**
     * @notice High water mark for performance fee calculation
     */
    uint96 public highWaterMark = 1e6;

    /**
     * @notice Accumulated platform fees
     */
    uint256 public accumulatedPlatformFees;

    /**
     * @notice Accumulated performance fees
     */
    uint256 public accumulatedPerformanceFees;

    /**
     * @notice Fee recipient address
     */
    address public feeRecipient;


    /**
     * @notice Pauses exchange rate updates
     */
    bool public isPaused;

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
        if (isPaused) revert CrestAccountant__Paused();
        _;
    }

    //============================== CONSTRUCTOR ===============================

    constructor(
        address payable _vault,
        address _usdt0,
        address _manager,
        address _owner,
        address _feeRecipient
    ) Auth(_owner, Authority(address(0))) {
        vault = CrestVault(_vault);
        usdt0 = ERC20(_usdt0);
        manager = CrestManager(_manager);
        feeRecipient = _feeRecipient;
        lastTotalAssets = 0; // Initialize to 0
    }

    //============================== ADMIN FUNCTIONS ===============================

    /**
     * @notice Updates fees based on current performance
     * @dev Called automatically when calculating exchange rate if profit detected
     */
    function _updateFees() internal {
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply == 0) return;

        uint256 currentAssets = getTotalAssets();

        // Initialize lastTotalAssets on first call
        if (lastTotalAssets == 0) {
            lastTotalAssets = currentAssets;
            return;
        }

        // Skip if no profit
        if (currentAssets <= lastTotalAssets) {
            lastTotalAssets = currentAssets;
            return;
        }

        uint256 profit = currentAssets - lastTotalAssets;

        // Calculate current rate
        uint96 currentRate = uint96((currentAssets * 1e6) / totalSupply);

        // Platform fee on all profit
        uint256 platformFee = (profit * platformFeeBps) / 10000;

        // Performance fee only on profit above high water mark
        uint256 performanceFee = 0;
        if (currentRate > highWaterMark) {
            uint256 outperformance = currentAssets - ((uint256(highWaterMark) * totalSupply) / 1e6);
            performanceFee = (outperformance * performanceFeeBps) / 10000;
            highWaterMark = currentRate;
        }

        accumulatedPlatformFees += platformFee;
        accumulatedPerformanceFees += performanceFee;
        lastTotalAssets = currentAssets;

        emit RateUpdated(0, currentRate, platformFee, performanceFee);
    }

    /**
     * @notice Collects accumulated fees
     */
    function collectFees() external requiresAuth {
        if (feeRecipient == address(0))
            revert CrestAccountant__NoFeeRecipient();

        uint256 platformFees = accumulatedPlatformFees;
        uint256 performanceFees = accumulatedPerformanceFees;

        accumulatedPlatformFees = 0;
        accumulatedPerformanceFees = 0;

        uint256 totalFees = platformFees + performanceFees;
        if (totalFees > 0) {
            // Mint fee shares to recipient
            uint256 feeShares = (totalFees * 1e6) / getRate();
            vault.enter(
                address(vault),
                ERC20(address(0)),
                0,
                feeRecipient,
                feeShares
            );
        }

        emit FeesCollected(feeRecipient, platformFees, performanceFees);
    }

    /**
     * @notice Updates fee parameters
     */
    function updateFees(
        uint16 _platformFeeBps,
        uint16 _performanceFeeBps
    ) external requiresAuth {
        if (_platformFeeBps > 500) revert CrestAccountant__InvalidFee(); // Max 5%
        if (_performanceFeeBps > 3000) revert CrestAccountant__InvalidFee(); // Max 30%

        platformFeeBps = _platformFeeBps;
        performanceFeeBps = _performanceFeeBps;

        emit FeesUpdated(_platformFeeBps, _performanceFeeBps);
    }

    /**
     * @notice Updates the fee recipient
     */
    function updateFeeRecipient(address _feeRecipient) external requiresAuth {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }


    /**
     * @notice Pauses exchange rate updates
     */
    function pause() external requiresAuth {
        isPaused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses exchange rate updates
     */
    function unpause() external requiresAuth {
        isPaused = false;
        emit Unpaused();
    }

    //============================== VIEW FUNCTIONS ===============================

    /**
     * @notice Returns the total assets under management
     */
    function getTotalAssets() public view returns (uint256) {
        // Get USDT0 balance in vault
        uint256 vaultBalance = usdt0.balanceOf(address(vault));

        // Add Hyperdrive value
        uint256 hyperdriveValue = vault.getHyperdriveValue();

        // Add Core position values from Manager
        uint256 corePositionValue = 0;
        if (address(manager) != address(0)) {
            // Get the current USD-denominated value of Core positions
            corePositionValue = manager.estimatePositionValue();
        }

        return vaultBalance + hyperdriveValue + corePositionValue;
    }

    /**
     * @notice Returns the current exchange rate after fees
     */
    function getRate() public view returns (uint256) {
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply == 0) return 1e6;

        uint256 totalAssets = getTotalAssets();

        // Deduct accumulated fees from assets
        uint256 totalFees = accumulatedPlatformFees + accumulatedPerformanceFees;
        if (totalAssets > totalFees) {
            totalAssets -= totalFees;
        }

        return (totalAssets * 1e6) / totalSupply;
    }

    /**
     * @notice Triggers fee update if there's unrealized profit
     * @dev Anyone can call this to update fees
     */
    function updateFees() external whenNotPaused {
        _updateFees();
    }

    /**
     * @notice Returns the current exchange rate
     */
    function exchangeRate() external view returns (uint256) {
        return getRate();
    }

    /**
     * @notice Converts assets to shares based on current exchange rate
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 rate = getRate();
        if (rate == 0) return 0;
        return (assets * 1e6) / rate;
    }

    /**
     * @notice Converts shares to assets based on current exchange rate
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return (shares * getRate()) / 1e6;
    }

}
