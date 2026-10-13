// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IUniswapV2Pair} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import {UniswapV2Library} from './UniswapV2Library.sol';
import {UniswapImmutables} from '../UniswapImmutables.sol';
import {Permit2Payments} from '../../Permit2Payments.sol';
import {Constants} from '../../../libraries/Constants.sol';
import {ERC20} from 'solmate/src/tokens/ERC20.sol';

/// @title Router for Uniswap v2 Trades
abstract contract V2SwapRouter is UniswapImmutables, Permit2Payments {
    error V2TooLittleReceived(); //@audit right here we have the V2tooLittleReceived
    error V2TooMuchRequested(); //@audit right here we have the too much requested 
    error V2InvalidPath(); //@audit right here too we have the V2 invalid path 
    error V2TooLittleReceivedPerHop(uint256 hopIndex, uint256 minPrice, uint256 price); //@audit right here too little received per hop
    error V2InvalidHopPriceLength(); //@audit right here we have the V2InvalidHoppRICElength

    function _v2Swap(
        address[] calldata path,
        address recipient,
        address pair,
        uint256[] calldata minHopPriceX36,
        uint256 amountOutMinimum
    ) private { //@audit right here we have the v2Swap too here 
        ERC20 tokenOut = ERC20(path[path.length - 1]); //@audit right here we store the final token out from this guy here 
        uint256 balanceBefore = tokenOut.balanceOf(recipient); //@audit right here we have the baalnceOf the recipient 

        unchecked {
            // cached to save on duplicate operations
            (address token0,) = UniswapV2Library.sortTokens(path[0], path[1]); //@audit right here we want to sort them tokens right away 
            uint256 finalPairIndex = path.length - 1; //@audit right here we have the finalPairIndex 
            uint256 penultimatePairIndex = finalPairIndex - 1; //@audit right here we have the penUltimateIndex 
            bool minHopPriceEnabled = minHopPriceX36.length != 0; //@audit right here minHopPriceEnabled 

            for (uint256 i; i < finalPairIndex; i++) {
                (address input, address output) = (path[i], path[i + 1]); //@audit right here we have the input and output 
                (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0); //@audit right here we have the reserve0 and reserve1

                    //@audit right here we have the reserve1 and reserve0 too

                // Note: amountInput is the pair's whole balance excess, so it counts tokens any third party transferred in.
                // The larger apparent trade earns a worse average rate, which can trip minHopPriceX36 and revert the
                // route. A donation below that bound, or with the bound disabled, is simply swapped along with the input.
                // Any excess left in the pair can be claimed through the permissionless skim(to) by whoever calls it first.
                uint256 amountInput = ERC20(input).balanceOf(pair) - reserveInput; //@audit right here we got the balanceOf(pair) - reserveInput
                uint256 amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
               
                (uint256 amount0Out, uint256 amount1Out) =
                    input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
           
                address nextPair; //@audit right here we got the nextPair from there 
                (nextPair, token0) = i < penultimatePairIndex
                    ? UniswapV2Library.pairAndToken0For( //@audit right here we got the nextPair right here and there 
                        UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, output, path[i + 2]
                    ) //@audit right here it makes a whole lot of sense
                    : (recipient, address(0));

                // if minHopPrice is being used, we need to check output balance change
                if (minHopPriceEnabled && minHopPriceX36[i] != 0) { //@audit right here if the minHopPrice is enabled 
                    uint256 recipientBalance = ERC20(output).balanceOf(nextPair);
                    IUniswapV2Pair(pair).swap(amount0Out, amount1Out, nextPair, new bytes(0)); //@audit right here we performed a swap given the amount0out and the amount1Out 
                    amountOutput = ERC20(output).balanceOf(nextPair) - recipientBalance; //@audit right here this one makes sense 


                    //@audit right here we have the amountOutput * price_precision / amountInput 
                    uint256 price = amountOutput * Constants.PRICE_PRECISION / amountInput; //@audit right here we took the ratio of the amountOutput right here 
                    uint256 minPrice = minHopPriceX36[i]; //@audit right here we got the minHopPricex36[i]
                    if (price < minPrice) revert V2TooLittleReceivedPerHop(i, minPrice, price); //@audit right here if the price < minPrice 
                } else {
                    //@audit right here we got the swap system right here
                    IUniswapV2Pair(pair).swap(amount0Out, amount1Out, nextPair, new bytes(0)); //@audit right here we split the pair out on the tokens from there 
                } //@audit right here we have the pair and then we swap it out from there 

                pair = nextPair; //@audit right here we got the nextpair
            }
        }

        // Delivery is measured at the recipient, so a token that hands over less than the pairs computed (fee on
        // transfer, withholding, or share-based rounding such as stETH delivering 1-2 wei less, at any hop) fails
        // the route instead of leaving a silent shortfall.

        //@audit right here we have the balanceOf(recipient)
        //@audit right here did the balance of the recipient ever changed 
        //@audit right here we checked the token balance of the recipient we removed the balanceBefore and then we checked the amountOutMINIMUM to confirm this guy
        if (tokenOut.balanceOf(recipient) - balanceBefore < amountOutMinimum) revert V2TooLittleReceived();
    }

    /// @notice Performs a Uniswap v2 exact input swap
    /// @param recipient The recipient of the output tokens
    /// @param amountIn The amount of input tokens for the trade
    /// @param amountOutMinimum The minimum desired amount of output tokens
    /// @param path The path of the trade as an array of token addresses
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v2SwapExactInput(
        address recipient, //@audit right here we have the recipient 
        uint256 amountIn, //@audit right here we also have the amountIn
        uint256 amountOutMinimum, //@audit right here we also have the amountOutMinimum
        address[] calldata path, //@audit witht the path too
        address payer, //@audit right here we also have the payer too 
        uint256[] calldata minHopPriceX36 //@audit right here we also have the minHoppricex36
    ) internal {
        if (path.length < 2) revert V2InvalidPath(); //@audit right here if it is less than 2 we revert 
        if (minHopPriceX36.length != 0 && minHopPriceX36.length != path.length - 1) {
            revert V2InvalidHopPriceLength(); //@audit right here if the minHopPricex36.length != 0 and the minHopPricex36.length != path.length -1 
        } //@audit ensuring the minPrice system is all good right here and there 


        address firstPair = //@audit right here we have the 
            UniswapV2Library.pairFor(UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, path[0], path[1]);
        
        if ( // path[0] doesn't mean this is token 1 or not 
            amountIn != Constants.ALREADY_PAID // amountIn of 0 to signal that the pair already has the tokens
        ) { //@audit right here we then payOrPermit2Transfer 
            payOrPermit2Transfer(path[0], payer, firstPair, amountIn); //@audit right here we have the constant.already_paid 
        }

        _v2Swap(path, recipient, firstPair, minHopPriceX36, amountOutMinimum); //@audit right here we then want to swap
    }

    /// @notice Performs a Uniswap v2 exact output swap
    /// @param recipient The recipient of the output tokens
    /// @param amountOut The amount of output tokens to receive for the trade
    /// @param amountInMaximum The maximum desired amount of input tokens
    /// @param path The path of the trade as an array of token addresses
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v2SwapExactOutput(
        address recipient, //@audit right here we have the recipient we are working with
        uint256 amountOut, //@audit right here too we have the amountOut
        uint256 amountInMaximum, //@audit right here we have the amountInMaximum
        address[] calldata path, //@audit right here we have the path address[] calldata path
        address payer, //@audit right here we have the payer too 
        uint256[] calldata minHopPriceX36 //@audit right here we have the minHopPriceX36
    ) internal {
        if (path.length < 2) revert V2InvalidPath(); //@audit right here we checked if the path.length < 2 then we revert 
        if (minHopPriceX36.length != 0 && minHopPriceX36.length != path.length - 1) {
            revert V2InvalidHopPriceLength(); //@audit right here we checked if the length is not zero and the minHopPricex36.length != path.length - 1
        }

        (uint256 amountIn, address firstPair) = //@audit right here we got the amountIn and the firstpair 
            UniswapV2Library.getAmountInMultihop(UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, amountOut, path);
        
        if (amountIn > amountInMaximum) revert V2TooMuchRequested(); //@audit right here there is no check against zero in amountInmAxu
        //@audit right here if the amountIn is greater than amountInMaximum

        //@audit right here too that's what we perform here 
        payOrPermit2Transfer(path[0], payer, firstPair, amountIn); //@audit right here we payOrPermit2Transfer 
       
        // exact output requires full delivery, so the requested amount is also the minimum
        _v2Swap(path, recipient, firstPair, minHopPriceX36, amountOut); //@audit right here we performed the amountOutMinimum from here 
    }
}
