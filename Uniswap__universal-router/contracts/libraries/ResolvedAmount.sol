// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Constants} from './Constants.sol';
import {RESOLVED_AMOUNT_SLOT} from './TransientSlots.sol';

/// @notice A transient register holding an amount resolved onchain by a RESOLVE command, for a later
/// command to consume via the Constants.USE_RESOLVED_AMOUNT sentinel in one of its amount fields.
/// @dev One register is shared by a plan and all of its sub-plans, and every consumer reads the latest value
/// written. A sub-plan starts with its parent's value, and a RESOLVE inside a sub-plan that succeeds replaces the
/// parent's value for the parent's later commands. A sub-plan that reverts under FLAG_ALLOW_REVERT has all of its
/// writes undone, its RESOLVE included, so the parent keeps the value it had before the sub-plan ran. The
/// top-level execute clears the register on exit so it never leaks into a later execute in the same transaction.
/// Zero means empty: RESOLVE clears the register whenever it fails, and a resolver returning zero counts as a
/// failure, so no command acts on a value no RESOLVE produced.
library ResolvedAmount {
    /// @notice Thrown when a command consumes the USE_RESOLVED_AMOUNT sentinel while the register is empty
    error ResolvedAmountUnset();

    function set(uint256 amount) internal {
        assembly ('memory-safe') {
            tstore(RESOLVED_AMOUNT_SLOT, amount)
        }
    }

    function get() internal view returns (uint256 amount) {
        assembly ('memory-safe') { //@audit right here we get the tload 
            amount := tload(RESOLVED_AMOUNT_SLOT)
        }
    }

    function reset() internal {
        assembly ('memory-safe') { //@audit right here we have a tstore and then we just set it 0 from there 
            tstore(RESOLVED_AMOUNT_SLOT, 0)
        }
    }

    /// @notice Maps a command's amount field through the register: the USE_RESOLVED_AMOUNT sentinel reads the
    /// register, any other value passes through unchanged
    /// @dev Reverts on an empty register so the sentinel can never fall through as a zero amount, which the v4
    /// swap helpers would read as OPEN_DELTA
    function map(uint256 amount) internal view returns (uint256) { //@audit right here we want to map 
        if (amount != Constants.USE_RESOLVED_AMOUNT) return amount; //@audit right here if the amount != USE_resolved_amount 
        //@audit right here we try to use the resolved_amount we then return the amount from here 

        amount = get(); //@audit then we get the amount
        if (amount == 0) revert ResolvedAmountUnset(); //@audit right here if the amount is 0 then we revert 
        return amount; //@audit right here we returned the amount
        //@audit right here we have the amount gotten to be executed from there too 
    }
}
