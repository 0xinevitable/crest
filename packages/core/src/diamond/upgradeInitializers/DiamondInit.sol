// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibCrestStorage } from "../libraries/LibCrestStorage.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { _IERC165 } from "../interfaces/IERC165.sol";

contract DiamondInit {
    struct InitArgs {
        address usdt0;
        address curator;
        address feeRecipient;
        uint64 shareLockPeriod;
        uint16 platformFeeBps;
        uint16 performanceFeeBps;
        uint16 maxSlippageBps;
    }

    function init(InitArgs memory _args) external {
        // Add ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(_IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;

        // Initialize Crest storage
        LibCrestStorage.CrestStorage storage cs = LibCrestStorage
            .crestStorage();

        require(!cs.initialized, "DiamondInit: Already initialized");
        cs.initialized = true;

        // Initialize Teller state
        cs.usdt0 = ERC20(_args.usdt0);
        cs.shareLockPeriod = _args.shareLockPeriod;
        cs.isTellerPaused = false;

        // Initialize Manager state
        cs.curator = _args.curator;
        cs.maxSlippageBps = _args.maxSlippageBps;
        cs.isManagerPaused = false;

        // Initialize Accountant state
        cs.platformFeeBps = _args.platformFeeBps;
        cs.performanceFeeBps = _args.performanceFeeBps;
        cs.highWaterMark = 1e6; // Initialize at 1:1 ratio
        cs.feeRecipient = _args.feeRecipient;
        cs.isAccountantPaused = false;
        cs.lastTotalAssets = 0;

        // Initialize empty position structs
        cs.currentSpotPosition = LibCrestStorage.Position({
            index: 0,
            isLong: false,
            size: 0,
            entryPrice: 0,
            timestamp: 0
        });

        cs.currentPerpPosition = LibCrestStorage.Position({
            index: 0,
            isLong: false,
            size: 0,
            entryPrice: 0,
            timestamp: 0
        });
    }
}
