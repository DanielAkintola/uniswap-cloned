// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {SafeCallback} from "./SafeCallback.sol";
import {CalldataDecoder} from "../libraries/CalldataDecoder.sol";
import {ActionConstants} from "../libraries/ActionConstants.sol";
import {IMsgSender} from "../interfaces/IMsgSender.sol";

/// @notice Abstract contract for performing a combination of actions on Uniswap v4.
/// @dev Suggested uint256 action values are defined in Actions.sol, however any definition can be used
abstract contract BaseActionsRouter is IMsgSender, SafeCallback {
    using CalldataDecoder for bytes;

    /// @notice emitted when different numbers of parameters and actions are provided
    error InputLengthMismatch();

    /// @notice emitted when an inheriting contract does not support an action
    error UnsupportedAction(uint256 action);

    constructor(IPoolManager _poolManager) SafeCallback(_poolManager) {} //@audit right here too we have the SafeCallback with the poolManager passed in as the data needed 

    /// @notice internal function that triggers the execution of a set of actions on v4
    /// @dev inheriting contracts should call this function to trigger execution
    function _executeActions(bytes calldata unlockData) internal {
        //@audit right here we have the pool manager unlock from here with the unlockData
        poolManager.unlock(unlockData); //@audit right here we have the poolManager to unlock the data 
    } //@audit right here we want to unlock the data from here 

    /// @notice function that is called by the PoolManager through the SafeCallback.unlockCallback
    /// @param data Abi encoding of (bytes actions, bytes[] params)
    /// where params[i] is the encoded parameters for actions[i]
    function _unlockCallback(bytes calldata data) internal override returns (bytes memory) {
        // abi.decode(data, (bytes, bytes[]));
        (bytes calldata actions, bytes[] calldata params) = data.decodeActionsRouterParams(); 
        //@audit right here we want to execute the actions without unlock right here we then move
        //@audit right here so we have the data which is decoded 
        _executeActionsWithoutUnlock(actions, params); //@audit right here we have the unlockCallback too
        return ""; //@audit right here we returned the empty string
    }

    function _executeActionsWithoutUnlock(bytes calldata actions, bytes[] calldata params) internal {
        uint256 numActions = actions.length;  //@audit right here we got the actions.legnth 
        //@audit right here we have the actions.length
        //@audit right here we have the system 

        //@audit right here we checked if the actions length is the same as the bytes array
        if (numActions != params.length) revert InputLengthMismatch(); //@audit right herre if the numAction != params.legnth then we revert 
        //@audit right here we have the actionIndex < numActions and then the actionIndex
        for (uint256 actionIndex = 0; actionIndex < numActions; actionIndex++) { //@audit right here we went through 
            uint256 action = uint8(actions[actionIndex]);  //@audit right here for each of the actionIndex
            //@audit right here we went through the actions 
            //@audit right here we have to handle the action right here with the action and the param[actionIndex]
            _handleAction(action, params[actionIndex]); //@audit right here we have the handle action here with the params[actionIndex]
        } //@audit right here we want to handle action too 
    }

    /// @notice function to handle the parsing and execution of an action and its parameters
    function _handleAction(uint256 action, bytes calldata params) internal virtual; //@audit right here it is internal right here 

    /// @notice function that returns address considered executor of the actions
    /// @dev The other context functions, _msgData and _msgValue, are not supported by this contract
    /// In many contracts this will be the address that calls the initial entry point that calls `_executeActions`
    /// `msg.sender` shouldn't be used, as this will be the v4 pool manager contract that calls `unlockCallback`
    /// If using ReentrancyLock.sol, this function can return _getLocker()
    function msgSender() public view virtual returns (address);

    /// @notice Calculates the address for a action
    function _mapRecipient(address recipient) internal view returns (address) {
        if (recipient == ActionConstants.MSG_SENDER) { //@audit right here we checked if the recipient is the same as the sender 
            return msgSender();  //@audit right here if it is the msg.sender 
          
            //@audit right here then we get the msgSENDER 
            //@audit right here we returned the sender 

        } else if (recipient == ActionConstants.ADDRESS_THIS) {
            //@audit right here we also have the address_this to work with too
            //@audit right here we checked if the 
            return address(this); //@audit right here if it is address_this then we return address_this
        } else { //@audit right here we returned the recipient 
            return recipient; //@audit right here then we just return the recipient 
        } //@audit right here recipient right away fuck it bro
    }

    /// @notice Calculates the payer for an action
    function _mapPayer(bool payerIsUser) internal view returns (address) {
        return payerIsUser ? msgSender() : address(this);
    }
}
