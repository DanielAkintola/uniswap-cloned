// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {MigratorImmutables} from '../modules/MigratorImmutables.sol';
import {INonfungiblePositionManager} from '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import {Actions} from '@uniswap/v4-periphery/src/libraries/Actions.sol';
import {IERC721Permit} from '@uniswap/v3-periphery/contracts/interfaces/IERC721Permit.sol';
import {CalldataDecoder} from '@uniswap/v4-periphery/src/libraries/CalldataDecoder.sol';

/// @title V3 to V4 Migrator
/// @notice A contract that migrates liquidity from Uniswap V3 to V4
abstract contract V3ToV4Migrator is MigratorImmutables {
    using CalldataDecoder for bytes;

    error InvalidAction(bytes4 action); //@audit right here we have the error
    error OnlyMintAllowed(); //@audit right here we have the error
    error NotAuthorizedForToken(uint256 tokenId); //@audit right here we also have the error

    /// @dev validate if an action is decreaseLiquidity, collect, or burn
    function _isValidAction(bytes4 selector) private pure returns (bool) {
        return selector == INonfungiblePositionManager.decreaseLiquidity.selector //@audit right here we checked against all these guys right here 
            || selector == INonfungiblePositionManager.collect.selector //@audit right here we checked the selector from here too
            || selector == INonfungiblePositionManager.burn.selector; //@audit right here we checked if it is a burn or a collect guy 
    }

    /// @dev the caller is authorized for the token if its the owner, spender, or operator
    function _isAuthorizedForToken(address caller, uint256 tokenId) private view returns (bool) {
        address owner = V3_POSITION_MANAGER.ownerOf(tokenId); //@audit right here we have the owner_of that tokenId 

        return caller == owner || V3_POSITION_MANAGER.getApproved(tokenId) == caller
            || V3_POSITION_MANAGER.isApprovedForAll(owner, caller); //@audit right here or the getapproved for the tokenId 
    }

    /// @dev check that a call is to the ERC721 permit function
    function _checkV3PermitCall(bytes calldata inputs) internal pure {
        //@audit right here if the inputs's length is less than 4 then we revert
        if (inputs.length < 0x04) revert CalldataDecoder.SliceOutOfBounds(); //@audit right here if the inputs.length is less than 4 then we revert 

        bytes4 selector; //@audit right here 
        assembly { //@audit right here we get our selector from the inputs.offset from here 
            selector := calldataload(inputs.offset)
        }

        if (selector != IERC721Permit.permit.selector) {  //@audit right here we ensured whoever this is just the selector we are dealing with 
            revert InvalidAction(selector); //@audit we revert from here 
        } //@audit right here if the selector is not a oermit then we revert 
    }

    /// @dev check that the v3 position manager call is a safe call
    function _checkV3PositionManagerCall(bytes calldata inputs, address caller) internal view {
        if (inputs.length < 0x24) revert CalldataDecoder.SliceOutOfBounds(); //@audit right here if the inputs.length < 0x24

        bytes4 selector; //@audit right here we have the selector too here 
        assembly { //@audit we read the selector first 4 bytes 
            selector := calldataload(inputs.offset)
        } //@audit right here we got the selector from here 

        if (!_isValidAction(selector)) { //@audit right here we determine if the selector is a valid action 
            revert InvalidAction(selector); //@audit right here we revert with that selector
        } //@audit right here if it is not a valid action we revert 

        uint256 tokenId; //@audit right here this is a uint256 tokenId 
        assembly { //@audit right here we want to get the tokenId -> [offset, with the 0x04]
            // tokenId is always the first parameter in the valid actions
            tokenId := calldataload(add(inputs.offset, 0x04)) //@audit right here we added
        } //@audit right here we got the tokenId 

        // If any other address that is not the owner wants to call this function, it also needs to be approved (in addition to this contract)
        // This can be done in 2 ways:
        //    1. This contract is permitted for the specific token and the caller is approved for ALL of the owner's tokens
        //    2. This contract is permitted for ALL of the owner's tokens and the caller is permitted for the specific token
        //@audit right here we checked if it an authorizedToken or not if it is not then we revert the fuck away
        if (!_isAuthorizedForToken(caller, tokenId)) { //@audit right here we check if it is not authorizedForToken 
            revert NotAuthorizedForToken(tokenId); //@audit right here we revert unauthorized from here directly 
        }//@audit right here it has to be authorized for that tokenId 
    }

    /// @dev check that the v4 position manager call is a safe call
    /// of the position-altering Actions, we only allow Actions.MINT
    /// this is because, if a user could be tricked into approving the UniversalRouter for
    /// their position, an attacker could take their fees, or drain their entire position
    function _checkV4PositionManagerCall(bytes calldata inputs) internal view {
        if (inputs.length < 0x04) revert CalldataDecoder.SliceOutOfBounds(); //@audit right here we checked if the input's length is less than 0x04 and then we revert 

        bytes4 selector;
        assembly { //@audit right here we have the selector gotten out 
            selector := calldataload(inputs.offset) //@audit right here we performed the selector 
        }

        if (selector != V4_POSITION_MANAGER.modifyLiquidities.selector) { //@audit right here we checked the selector 
            revert InvalidAction(selector); //@audit right here if the selector is not the current selector chosen we revert 
        }

        // slice is `abi.encode(bytes unlockData, uint256 deadline)`
        bytes calldata slice = inputs[4:]; //@audit right here we got the sliced inputs 
        // the first bytes(0) extracts the unlockData parameter from modifyLiquidities
        // unlockData = `abi.encode(bytes actions, bytes[] params)`
        // the second bytes(0) extracts the actions parameter from unlockData
        bytes calldata actions = slice.toBytes(0).toBytes(0); //@audit right here we have the actions too here 
        uint256 numActions = actions.length; //@audit right here we have the number of actions too 

        for (uint256 actionIndex = 0; actionIndex < numActions; actionIndex++) {
            uint256 action = uint8(actions[actionIndex]); //@audit right here we have the actions given the actionIndex too

            if ( //@audit right here we then performed 
                action == Actions.INCREASE_LIQUIDITY || action == Actions.INCREASE_LIQUIDITY_FROM_DELTAS
                    || action == Actions.DECREASE_LIQUIDITY || action == Actions.BURN_POSITION
            ) { //@audit right here we revert 
                revert OnlyMintAllowed(); //@audit right here we keep pushing through too
            }
        }
    }
}
