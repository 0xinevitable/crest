// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin-v4/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-v4/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICoreWriter {
    function sendRawAction(bytes calldata data) external payable;
}

library HLConstants {
    address internal constant HYPE_SYSTEM_ADDRESS = 0x2222222222222222222222222222222222222222;
    uint160 internal constant BASE_SYSTEM_ADDRESS = uint160(0x4444444444444444444444444444444444444444);

    uint8 internal constant SPOT_SEND_ACTION = 1;
    uint8 internal constant TOKEN_DELEGATE_ACTION = 2;
    uint8 internal constant STAKING_DEPOSIT_ACTION = 3;
    uint8 internal constant STAKING_WITHDRAW_ACTION = 4;
    uint8 internal constant VAULT_TRANSFER_ACTION = 5;
    uint8 internal constant USD_CLASS_TRANSFER_ACTION = 6;
    uint8 internal constant LIMIT_ORDER_ACTION = 7;
    uint8 internal constant ADD_API_WALLET_ACTION = 8;
    uint8 internal constant CANCEL_ORDER_BY_OID_ACTION = 9;
    uint8 internal constant CANCEL_ORDER_BY_CLOID_ACTION = 10;
    uint8 internal constant FINALIZE_EVM_CONTRACT_ACTION = 11;

    function hypeTokenIndex() internal pure returns (uint64) {
        return 150; // HYPE token index
    }
}

library HLConversions {
    function evmToWei(uint64 token, uint256 evmAmount) internal pure returns (uint64) {
        // Simplified conversion - assumes 6 decimals for USDC
        if (token == 0) { // USDC
            return uint64(evmAmount / 1e12); // Convert from 18 to 6 decimals
        }
        return uint64(evmAmount);
    }

    function weiToEvm(uint64 token, uint64 weiAmount) internal pure returns (uint256) {
        // Simplified conversion - assumes 6 decimals for USDC
        if (token == 0) { // USDC
            return uint256(weiAmount) * 1e12; // Convert from 6 to 18 decimals
        }
        return uint256(weiAmount);
    }

    function weiToPerp(uint64 weiAmount) internal pure returns (uint64) {
        return weiAmount; // 1:1 for perp
    }
}

library HyperliquidLib {
    using SafeERC20 for IERC20;

    ICoreWriter constant coreWriter = ICoreWriter(0x3333333333333333333333333333333333333333);

    error HyperliquidLib__StillLockedUntilTimestamp(uint64 lockedUntilTimestamp);
    error HyperliquidLib__CannotSelfTransfer();
    error HyperliquidLib__HypeTransferFailed();
    error HyperliquidLib__CoreAmountTooLarge(uint256 amount);
    error HyperliquidLib__EvmAmountTooSmall(uint256 amount);

    function bridgeToCore(address tokenAddress, uint256 evmAmount) internal {
        uint64 tokenIndex = 0; // Simplified - assumes USDC
        address systemAddress = getSystemAddress(tokenIndex);
        uint64 coreAmount = HLConversions.evmToWei(tokenIndex, evmAmount);
        if (coreAmount == 0) revert HyperliquidLib__EvmAmountTooSmall(evmAmount);
        // For USDC
        IERC20(tokenAddress).safeTransfer(systemAddress, evmAmount);
    }

    function bridgeToCore(uint64 token, uint256 evmAmount) internal {
        uint64 coreAmount = HLConversions.evmToWei(token, evmAmount);
        if (coreAmount == 0) revert HyperliquidLib__EvmAmountTooSmall(evmAmount);
        address systemAddress = getSystemAddress(token);
        if (isHype(token)) {
            (bool success,) = systemAddress.call{value: evmAmount}("");
            if (!success) revert HyperliquidLib__HypeTransferFailed();
        } else {
            // For USDC - assuming token address would be looked up
            // In production, this would need proper token registry
            revert("Token bridging not fully implemented");
        }
    }

    function bridgeToEvm(uint64 token, uint256 amount, bool isEvmAmount) internal {
        address systemAddress = getSystemAddress(token);

        uint64 coreAmount;
        if (isEvmAmount) {
            coreAmount = HLConversions.evmToWei(token, amount);
            if (coreAmount == 0) revert HyperliquidLib__EvmAmountTooSmall(amount);
        } else {
            if (amount > type(uint64).max) revert HyperliquidLib__CoreAmountTooLarge(amount);
            coreAmount = uint64(amount);
        }

        spotSend(systemAddress, token, coreAmount);
    }

    function spotSend(address to, uint64 token, uint64 amountWei) internal {
        if (to == address(this)) revert HyperliquidLib__CannotSelfTransfer();

        coreWriter.sendRawAction(
            abi.encodePacked(uint8(1), HLConstants.SPOT_SEND_ACTION, abi.encode(to, token, amountWei))
        );
    }

    function transferUsdClass(uint64 ntl, bool toPerp) internal {
        coreWriter.sendRawAction(
            abi.encodePacked(uint8(1), HLConstants.USD_CLASS_TRANSFER_ACTION, abi.encode(ntl, toPerp))
        );
    }

    function placeLimitOrder(
        uint32 asset,
        bool isBuy,
        uint64 limitPx,
        uint64 sz,
        bool reduceOnly,
        uint8 encodedTif,
        uint128 cloid
    ) internal {
        coreWriter.sendRawAction(
            abi.encodePacked(
                uint8(1),
                HLConstants.LIMIT_ORDER_ACTION,
                abi.encode(asset, isBuy, limitPx, sz, reduceOnly, encodedTif, cloid)
            )
        );
    }

    function cancelOrderByCloid(uint32 asset, uint128 cloid) internal {
        coreWriter.sendRawAction(
            abi.encodePacked(uint8(1), HLConstants.CANCEL_ORDER_BY_CLOID_ACTION, abi.encode(asset, cloid))
        );
    }

    function getSystemAddress(uint64 index) internal pure returns (address) {
        if (index == HLConstants.hypeTokenIndex()) {
            return HLConstants.HYPE_SYSTEM_ADDRESS;
        }
        return address(HLConstants.BASE_SYSTEM_ADDRESS + index);
    }

    function isHype(uint64 index) internal pure returns (bool) {
        return index == HLConstants.hypeTokenIndex();
    }
}