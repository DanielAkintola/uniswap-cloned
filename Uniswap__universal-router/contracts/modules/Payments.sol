// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Constants} from '../libraries/Constants.sol';
import {ActionConstants} from '@uniswap/v4-periphery/src/libraries/ActionConstants.sol';
import {BipsLibrary} from '@uniswap/v4-periphery/src/libraries/BipsLibrary.sol';
import {PaymentsImmutables} from '../modules/PaymentsImmutables.sol';
import {SafeTransferLib} from 'solmate/src/utils/SafeTransferLib.sol';
import {ERC20} from 'solmate/src/tokens/ERC20.sol';

/// @title Payments contract
/// @notice Performs various operations around the payment of ETH and tokens
abstract contract Payments is PaymentsImmutables {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;
    using BipsLibrary for uint256;

    error InsufficientToken();
    error InsufficientETH();
    error InvalidPortion();

    /// @notice Pays an amount of ETH or ERC20 to a recipient
    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive the payment
    /// @param value The amount to pay
    function pay(address token, address recipient, uint256 value) internal { //@audit right here we want to pay 
        if (token != Constants.ETH && value == ActionConstants.CONTRACT_BALANCE) { //@audit right here and the value == contract balance then we re-write the value 
            value = ERC20(token).balanceOf(address(this)); //@audit right here we checked if the token = 
        } //@audit right here we have the token != ETH and the value == balance 


        //@audit right here we _transfer again
        _transfer(token, recipient, value);
    }

    /// @notice Pays a proportion of the contract's ETH or ERC20 to a recipient
    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive payment
    /// @param bips Portion in bips of whole balance of the contract
    function payPortion(address token, address recipient, uint256 bips) internal {
        _transfer(token, recipient, _balanceOf(token).calculatePortion(bips)); //@audit right here we have the balance of the token we then calculated the portion of the bips and then 
        //@audit we transferred the token to the recipient like that 
    }

    /// @notice Pays a proportion of the contract's ETH or ERC20 to a recipient with 1e18 precision
    /// @param token The token to pay (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive payment
    /// @param portion Portion of whole balance of the contract, where 1e18 represents 100%
    function payPortionFullPrecision(address token, address recipient, uint256 portion) internal { //@audit right here we have the token, recipient and the portion
        if (portion > 1e18) revert InvalidPortion(); 
        //@audit right here we have the portion > 1e18 
        //@audit right here we have the token, recipient and the portion
        //@audit right here we checked if the portion is greater than 1e18
        //@audit right here idk if the token supported is gonna have a whatever 
        _transfer(token, recipient, _balanceOf(token) * portion / 1e18);  //@audit right here transfer -> token ->
        //@audit right we then transfeereed the token 

    }

    /// @notice Sweeps all of the contract's ERC20 or ETH to an address
    /// @param token The token to sweep (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive payment
    /// @param amountMinimum The minimum desired amount
    function sweep(address token, address recipient, uint256 amountMinimum) internal {
        uint256 balance = _balanceOf(token);

        if (balance < amountMinimum) { //@audit right here if we have the balance < amountminimum  
            if (token == Constants.ETH) revert InsufficientETH(); //@audit right here we checked if the token == ETH and then we revert 
            revert InsufficientToken(); //@audit right here we reverted insufficientToken()
        }

        if (balance > 0) _transfer(token, recipient, balance); //@audit right here we checked if the balance > 0 and then we _transfer given the 
        //@audit the token, recipient and the balance 
    }

    /// @notice Wraps an amount of ETH into WETH
    /// @param recipient The recipient of the WETH
    /// @param amount The amount to wrap (can be CONTRACT_BALANCE)
    function wrapETH(address recipient, uint256 amount) internal { //@audit we have the recipient and the amount we want to wrap
        if (amount == ActionConstants.CONTRACT_BALANCE) { //@audit right here if it is a contract balance 
            amount = address(this).balance;
            //@audit if the amount is a contract_balance then we use address(this)
        } else if (amount > address(this).balance) {
            //@audit right here if it is the balance then we revert too 
             //@audit right here if the amount > address(this).balance we revert 
            revert InsufficientETH();
        }

        if (amount > 0) { //@audit right here if the amount > 0 
            WETH9.deposit{value: amount}(); //@audit we deposited the WETH9 the value given that amount
            //@audit we deposited that value 
            if (recipient != address(this)) { //@audit right here if the recipient != address(this)
                WETH9.transfer(recipient, amount); //@audit right here then we transfer the WETH9 to the recipient those amount 
            } //@audit right here we transfer the recipient that amount from there 
        }
    }

    /// @notice Unwraps all of the contract's WETH into ETH
    /// @param recipient The recipient of the ETH
    /// @param amountMinimum The minimum amount of ETH desired
    function unwrapWETH9(address recipient, uint256 amountMinimum) internal {
        uint256 value = WETH9.balanceOf(address(this)); //@audit right here we got the balance of this address
        if (value < amountMinimum) revert InsufficientETH(); //@audit if the value < amountMin then we revert  
        _unwrap(recipient, value); //@audit right here we want to unwrap from the recipient those value
        //@audit right here we got the value too from here then we unwrao the balance 
    }

    /// @notice Unwraps an exact amount of the contract's WETH into ETH
    /// @param recipient The recipient of the ETH
    /// @param amount The exact amount of WETH to unwrap
    function unwrapWETH9Exact(address recipient, uint256 amount) internal { //@audit right here we want 
        if (WETH9.balanceOf(address(this)) < amount) revert InsufficientETH(); //@audit right here if the WETH balance of address(this) > amount 
        _unwrap(recipient, amount); //@audit right here we unwrap the recipient and the amount too
    }

    /// @notice Unwraps an amount of WETH and forwards the ETH to a recipient
    /// @param recipient The recipient of the ETH; if this contract, the ETH is kept here
    /// @param amount The amount of WETH to unwrap
    function _unwrap(address recipient, uint256 amount) private {
        if (amount > 0) { //@audit right here if the amount > 0 
            WETH9.withdraw(amount); //@audit right here we want to withdraw that amount 
            //@audit right here we withdrew the amount from here too 
            if (recipient != address(this)) { //@audit right here if the recipient is not address this wetransfer the ETH
                recipient.safeTransferETH(amount); //@audit right here we transferred the eth to the amount 
            }
        }
    }

    /// @notice Returns the contract's balance of a token
    /// @param token The token to query (can be ETH using Constants.ETH)
    /// @return The contract's balance of the token, or its ETH balance if token is Constants.ETH
    function _balanceOf(address token) private view returns (uint256) {
        //@audit right here we want the balanceOf system with a token init
        //@audit then we use address(this).balance if the token is ETH or else we just token balanceof 
        return token == Constants.ETH ? address(this).balance : ERC20(token).balanceOf(address(this));
        //@audit right here we checked if the token == ETH then we used address(this).balance or else we use ERC20(TOKEN)
    }

    /// @notice Transfers an amount of ETH or ERC20 to a recipient
    /// @param token The token to transfer (can be ETH using Constants.ETH)
    /// @param recipient The address that will receive the transfer
    /// @param amount The amount to transfer
    function _transfer(address token, address recipient, uint256 amount) private { //@audit right here we have the 
        if (token == Constants.ETH) {  //@audit right here we got the ETH and then we transferred the 
            recipient.safeTransferETH(amount); //@audit right here we transfered the eth from here 
        } else {
            ERC20(token).safeTransfer(recipient, amount);  //@audit right here we transfere the recipeint 
        }
    }
}
