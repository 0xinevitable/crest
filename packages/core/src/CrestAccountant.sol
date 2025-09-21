// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from '@solmate/tokens/ERC20.sol';
import { FixedPointMathLib } from '@solmate/utils/FixedPointMathLib.sol';
import { Auth, Authority } from '@solmate/auth/Auth.sol';
import { CrestVault } from './CrestVault.sol';

contract CrestAccountant is Auth {
    using FixedPointMathLib for uint256;

    // ========================================= STATE =========================================

    /**
     * @notice The CrestVault contract
     */
    CrestVault public immutable vault;

    /**
     * @notice The current exchange rate (assets per share)
     * @dev Stored with 6 decimals precision (1e6 = 1:1 rate)
     */
    uint96 public exchangeRate = 1e6;

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
        address _owner,
        address _feeRecipient
    ) Auth(_owner, Authority(address(0))) {
        vault = CrestVault(_vault);
        feeRecipient = _feeRecipient;
    }

    //============================== ADMIN FUNCTIONS ===============================

    /**
     * @notice Updates the exchange rate based on current vault performance
     * @param totalAssets The total value of assets in the vault (in USDC)
     */
    function updateExchangeRate(
        uint256 totalAssets
    ) external requiresAuth whenNotPaused {
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply == 0) {
            // No shares minted yet, keep rate at 1:1
            return;
        }

        // Add Hyperdrive value from vault
        uint256 adjustedTotalAssets = totalAssets + vault.getHyperdriveValue();

        // Calculate new rate
        uint96 newRate = uint96((adjustedTotalAssets * 1e6) / totalSupply);

        // Calculate fees if rate increased
        uint256 platformFee = 0;
        uint256 performanceFee = 0;

        if (newRate > exchangeRate) {
            uint256 profit = (uint256(newRate - exchangeRate) * totalSupply) /
                1e6;

            // Platform fee on all profit
            platformFee = (profit * platformFeeBps) / 10000;

            // Performance fee only on profit above high water mark
            if (newRate > highWaterMark) {
                uint256 outperformance = (uint256(newRate - highWaterMark) *
                    totalSupply) / 1e6;
                performanceFee = (outperformance * performanceFeeBps) / 10000;
                highWaterMark = newRate;
            }

            // Deduct fees from new rate
            uint256 totalFees = platformFee + performanceFee;
            if (totalFees > 0) {
                newRate = uint96(
                    ((adjustedTotalAssets - totalFees) * 1e6) / totalSupply
                );
            }

            accumulatedPlatformFees += platformFee;
            accumulatedPerformanceFees += performanceFee;
        }

        uint96 oldRate = exchangeRate;
        exchangeRate = newRate;

        emit RateUpdated(oldRate, newRate, platformFee, performanceFee);
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
            uint256 feeShares = (totalFees * 1e6) / exchangeRate;
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
     * @notice Converts assets to shares based on current exchange rate
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        if (exchangeRate == 0) return 0;
        return (assets * 1e6) / exchangeRate;
    }

    /**
     * @notice Converts shares to assets based on current exchange rate
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return (shares * exchangeRate) / 1e6;
    }

    /**
     * @notice Returns the current exchange rate with proper decimals
     */
    function getRate() external view returns (uint256) {
        return exchangeRate;
    }

}
