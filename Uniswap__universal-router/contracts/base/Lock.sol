// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Locker} from '../libraries/Locker.sol';

/// @title Lock
/// @notice A contract that provides a reentrancy lock for external calls
contract Lock {
    /// @notice Thrown when attempting to reenter a locked function from an external caller
    error ContractLocked();

    /// @notice Modifier enforcing a reentrancy lock that allows self-reentrancy
    /// @dev If the contract is not locked, use msg.sender as the locker
    modifier isNotLocked() {
        // Apply a reentrancy lock for all external callers
        if (msg.sender != address(this)) {  //@audit right here we checked if the sender is not address(this)
            if (Locker.isLocked()) revert ContractLocked(); //@audit if the locker is not locked then we revert 
            Locker.set(msg.sender); //@audit right here we set the msg.sender
            _;
            Locker.set(address(0)); //@audit right here we set the address(0) from here 
        } else { //@audit right here we else we just continue from here 
            // The contract is allowed to reenter itself, so the lock is not checked
            _; //@audit right here we set the msg.sender from here 
        }
    }

    /// @notice return the current locker of the contract
    function _getLocker() internal view returns (address) {
        return Locker.get(); //@audit right here it has to be locked 
    }
}
