// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Vm } from "forge-std/Vm.sol";

import { TestHyperCore } from "./TestHyperCore.sol";
import { CoreWriterSim } from "@hyper-evm-lib/test/simulation/CoreWriterSim.sol";
import { PrecompileSim } from "@hyper-evm-lib/test/simulation/PrecompileSim.sol";
import { BboPrecompileSim } from "./BboPrecompileSim.sol";

import { HLConstants } from "@hyper-evm-lib/src/PrecompileLib.sol";

Vm constant vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
CoreWriterSim constant coreWriter = CoreWriterSim(
    0x3333333333333333333333333333333333333333
);

contract TestHypeSystemContract {
    receive() external payable {
        coreWriter.nativeTransferCallback{ value: msg.value }(
            msg.sender,
            msg.sender,
            msg.value
        );
    }
}

/**
 * @title TestCoreSimulatorLib
 * @dev A library used to simulate HyperCore functionality in foundry tests with BBO support
 */
library TestCoreSimulatorLib {
    uint256 constant NUM_PRECOMPILES = 17;

    TestHyperCore constant hyperCore =
        TestHyperCore(payable(0x9999999999999999999999999999999999999999));

    // ERC20 Transfer event signature
    bytes32 constant TRANSFER_EVENT_SIG =
        keccak256("Transfer(address,address,uint256)");

    function init() internal returns (TestHyperCore) {
        vm.pauseGasMetering();

        TestHyperCore coreImpl = new TestHyperCore();

        vm.etch(address(hyperCore), address(coreImpl).code);
        hyperCore.setStakingYieldIndex(1e18);
        vm.etch(address(coreWriter), type(CoreWriterSim).runtimeCode);

        // Initialize precompiles
        for (uint160 i = 0; i < NUM_PRECOMPILES; i++) {
            address precompileAddress = address(
                uint160(0x0000000000000000000000000000000000000800) + i
            );

            // Use BboPrecompileSim for the BBO precompile (0x80e)
            if (precompileAddress == HLConstants.BBO_PRECOMPILE_ADDRESS) {
                vm.etch(precompileAddress, type(BboPrecompileSim).runtimeCode);
            } else {
                vm.etch(precompileAddress, type(PrecompileSim).runtimeCode);
            }
            vm.allowCheatcodes(precompileAddress);
        }

        // System addresses
        address hypeSystemAddress = address(
            0x2222222222222222222222222222222222222222
        );
        vm.etch(hypeSystemAddress, type(TestHypeSystemContract).runtimeCode);

        // Start recording logs for token transfer tracking
        vm.recordLogs();

        vm.allowCheatcodes(address(hyperCore));
        vm.allowCheatcodes(address(coreWriter));

        vm.resumeGasMetering();

        return hyperCore;
    }

    function nextBlock(bool expectRevert) internal {
        // Get all recorded logs
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Process any ERC20 transfers to system addresses (EVM->Core transfers are processed before CoreWriter actions)
        for (uint256 i = 0; i < entries.length; i++) {
            Vm.Log memory entry = entries[i];

            // Check if it's a Transfer event
            if (entry.topics[0] == TRANSFER_EVENT_SIG) {
                address from = address(uint160(uint256(entry.topics[1])));
                address to = address(uint160(uint256(entry.topics[2])));
                uint256 amount = abi.decode(entry.data, (uint256));

                // Check if destination is a system address
                if (isSystemAddress(to)) {
                    uint64 tokenIndex = getTokenIndexFromSystemAddress(to);

                    // Call tokenTransferCallback on HyperCoreWrite
                    hyperCore.executeTokenTransfer(
                        address(0),
                        tokenIndex,
                        from,
                        amount
                    );
                }
            }
        }

        // Clear recorded logs for next block
        vm.recordLogs();

        // Advance block
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);

        // liquidate any positions that are liquidatable
        hyperCore.liquidatePositions();

        // Process any pending actions
        coreWriter.executeQueuedActions(expectRevert);

        // Process pending orders
        hyperCore.processPendingOrders();
    }

    function nextBlock() internal {
        nextBlock(false);
    }

    ////// Testing Config Setters /////////

    function setRevertOnFailure(bool _revertOnFailure) internal {
        coreWriter.setRevertOnFailure(_revertOnFailure);
    }

    // cheatcodes //
    function forceAccountActivation(address account) internal {
        hyperCore.forceAccountActivation(account);
    }

    function forceSpotBalance(
        address account,
        uint64 token,
        uint64 _wei
    ) internal {
        hyperCore.forceSpotBalance(account, token, _wei);
    }

    function forcePerpBalance(address account, uint64 usd) internal {
        hyperCore.forcePerpBalance(account, usd);
    }

    function forceStakingBalance(address account, uint64 _wei) internal {
        hyperCore.forceStakingBalance(account, _wei);
    }

    function forceDelegation(
        address account,
        address validator,
        uint64 amount,
        uint64 lockedUntilTimestamp
    ) internal {
        hyperCore.forceDelegation(
            account,
            validator,
            amount,
            lockedUntilTimestamp
        );
    }

    function forceVaultEquity(
        address account,
        address vault,
        uint64 usd,
        uint64 lockedUntilTimestamp
    ) internal {
        hyperCore.forceVaultEquity(account, vault, usd, lockedUntilTimestamp);
    }

    function setMarkPx(uint32 perp, uint64 markPx) internal {
        hyperCore.setMarkPx(perp, markPx);
    }

    function setMarkPx(
        uint32 perp,
        uint64 priceDiffBps,
        bool isIncrease
    ) internal {
        hyperCore.setMarkPx(perp, priceDiffBps, isIncrease);
    }

    function setSpotPx(uint32 spotMarketId, uint64 spotPx) internal {
        hyperCore.setSpotPx(spotMarketId, spotPx);
    }

    function setSpotPx(
        uint32 spotMarketId,
        uint64 priceDiffBps,
        bool isIncrease
    ) internal {
        hyperCore.setSpotPx(spotMarketId, priceDiffBps, isIncrease);
    }

    function setVaultMultiplier(address vault, uint64 multiplier) internal {
        hyperCore.setVaultMultiplier(vault, multiplier);
    }
    function setStakingYieldIndex(uint64 multiplier) internal {
        hyperCore.setStakingYieldIndex(multiplier);
    }

    function forcePosition(
        address account,
        uint16 perpIndex,
        int64 szi,
        uint64 entryNtl
    ) internal {
        hyperCore.forcePosition(account, perpIndex, szi, entryNtl);
    }

    ///// VIEW AND PURE /////////

    function isSystemAddress(address addr) internal view returns (bool) {
        // Check if it's the HYPE system address
        if (addr == address(0x2222222222222222222222222222222222222222)) {
            return true;
        }

        // Check if it's a token system address (0x2000...0000 + index)
        uint160 baseAddr = uint160(0x2000000000000000000000000000000000000000);
        uint160 addrInt = uint160(addr);

        if (addrInt >= baseAddr && addrInt < baseAddr + 10000) {
            uint64 tokenIndex = uint64(addrInt - baseAddr);

            return tokenExists(tokenIndex);
        }

        return false;
    }

    function getTokenIndexFromSystemAddress(
        address systemAddr
    ) internal pure returns (uint64) {
        if (systemAddr == address(0x2222222222222222222222222222222222222222)) {
            return 150; // HYPE token index
        }
        return
            uint64(
                uint160(systemAddr) -
                    uint160(0x2000000000000000000000000000000000000000)
            );
    }

    function tokenExists(uint64 token) internal view returns (bool) {
        (bool success, ) = HLConstants.TOKEN_INFO_PRECOMPILE_ADDRESS.staticcall(
            abi.encode(token)
        );
        return success;
    }

    // BBO configuration functions
    function setBboForSpot(uint32 spotIndex) internal {
        BboPrecompileSim(payable(HLConstants.BBO_PRECOMPILE_ADDRESS)).setAsSpot(
            uint64(spotIndex)
        );
    }

    function setBboForPerp(uint32 perpIndex) internal {
        BboPrecompileSim(payable(HLConstants.BBO_PRECOMPILE_ADDRESS)).setAsPerp(
            uint64(perpIndex)
        );
    }

    function setBbo(uint64 assetId, uint64 bid, uint64 ask) internal {
        BboPrecompileSim(payable(HLConstants.BBO_PRECOMPILE_ADDRESS)).setBbo(
            assetId,
            bid,
            ask
        );
    }
}
