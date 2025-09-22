// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { BeforeTransferHook } from "../../interfaces/BeforeTransferHook.sol";
import { IHyperdriveMarket } from "../../interfaces/IHyperdriveMarket.sol";

library LibCrestStorage {
    bytes32 constant CREST_STORAGE_POSITION =
        keccak256("crest.diamond.storage");

    struct Position {
        uint32 index;
        bool isLong;
        uint64 size;
        uint64 entryPrice;
        uint256 timestamp;
    }

    struct CrestStorage {
        // Vault State
        BeforeTransferHook hook;
        uint32 currentSpotIndex;
        uint32 currentPerpIndex;
        IHyperdriveMarket hyperdriveMarket;
        uint256 hyperdriveShares;
        mapping(address => bool) authorized;
        // Teller State
        ERC20 usdt0;
        uint64 shareLockPeriod;
        mapping(address => uint256) shareUnlockTime;
        bool isTellerPaused;
        // Manager State
        Position currentSpotPosition;
        Position currentPerpPosition;
        uint256 totalAllocated;
        bool isManagerPaused;
        address curator;
        uint16 maxSlippageBps;
        // Accountant State
        uint256 lastTotalAssets;
        uint16 platformFeeBps;
        uint16 performanceFeeBps;
        uint96 highWaterMark;
        uint256 accumulatedPlatformFees;
        uint256 accumulatedPerformanceFees;
        address feeRecipient;
        bool isAccountantPaused;
        // Shared initialization flag
        bool initialized;
    }

    function crestStorage() internal pure returns (CrestStorage storage cs) {
        bytes32 position = CREST_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}
