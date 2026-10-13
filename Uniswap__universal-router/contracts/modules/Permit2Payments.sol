// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';
import {SafeCast160} from 'permit2/src/libraries/SafeCast160.sol';
import {Payments} from './Payments.sol';
import {ResolvedAmount} from '../libraries/ResolvedAmount.sol';

/// @title Payments through Permit2
/// @notice Performs interactions with Permit2 to transfer tokens
abstract contract Permit2Payments is Payments {
    using SafeCast160 for uint256;

    error FromAddressIsNotOwner();

    /// @notice Performs a transferFrom on Permit2
    /// @param token The token to transfer
    /// @param from The address to transfer from
    /// @param to The recipient of the transfer
    /// @param amount The amount to transfer
    function permit2TransferFrom(address token, address from, address to, uint160 amount) internal {
        //@audit right here that's what is the most important 
        PERMIT2.transferFrom(from, to, amount, token); //@audit right here we have permot2
    } 
    
    //@audit right here we want to permit2 and perform transferFrom from there with the from, to, amount and the token 

    /// @notice Performs a batch transferFrom on Permit2
    /// @dev Transfers one detail at a time so each amount can be mapped through the RESOLVE register without
    /// copying the calldata array to memory. Permit2's batch transferFrom performs the same per-detail transfers.
    /// @param batchDetails An array detailing each of the transfers that should occur
    /// @param owner The address that should be the owner of all transfers
    function permit2TransferFrom(IAllowanceTransfer.AllowanceTransferDetails[] calldata batchDetails, address owner)
        internal
    { 
        uint256 batchLength = batchDetails.length; //@audit right here too we got the lenght 
        for (uint256 i = 0; i < batchLength; ++i) {
            IAllowanceTransfer.AllowanceTransferDetails calldata details = batchDetails[i];
            if (details.from != owner) revert FromAddressIsNotOwner(); //@audit right here we got the amount to deal with 
            //@audit right here we got the details.token, owner, with the to with the resolvedamount.map
            permit2TransferFrom(details.token, owner, details.to, ResolvedAmount.map(details.amount).toUint160());
        }
    }

    /// @notice Either performs a regular payment or transferFrom on Permit2, depending on the payer address
    /// @param token The token to transfer
    /// @param payer The address to pay for the transfer
    /// @param recipient The recipient of the transfer
    /// @param amount The amount to transfer
    function payOrPermit2Transfer(address token, address payer, address recipient, uint256 amount) internal { //@note when we understand the system better see if there is anyway this can break the logic
        if (payer == address(this)) pay(token, recipient, amount); //@audit right here we have if the payer is address(this) -> pay(token, recipient) -> 
        else permit2TransferFrom(token, payer, recipient, amount.toUint160()); //@audit right here else we performed permit to transfer
    }
}
