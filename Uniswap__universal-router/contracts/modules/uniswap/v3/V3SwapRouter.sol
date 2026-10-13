// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {V3Path} from './V3Path.sol';
import {BytesLib} from './BytesLib.sol';
import {SafeCast} from '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {IUniswapV3SwapCallback} from '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import {ActionConstants} from '@uniswap/v4-periphery/src/libraries/ActionConstants.sol';
import {Constants} from '../../../libraries/Constants.sol';
import {CalldataDecoder} from '@uniswap/v4-periphery/src/libraries/CalldataDecoder.sol';
import {Permit2Payments} from '../../Permit2Payments.sol';
import {UniswapImmutables} from '../UniswapImmutables.sol';
import {MaxInputAmount} from '../../../libraries/MaxInputAmount.sol';
import {ERC20} from 'solmate/src/tokens/ERC20.sol';

/// @title Router for Uniswap v3 Trades
abstract contract V3SwapRouter is UniswapImmutables, Permit2Payments, IUniswapV3SwapCallback {
    using V3Path for bytes;
    using BytesLib for bytes;
    using CalldataDecoder for bytes;
    using SafeCast for uint256;

    error V3InvalidSwap();
    error V3TooLittleReceived();
    error V3TooMuchRequested();
    error V3InvalidAmountOut();
    error V3InvalidCaller();
    error V3TooLittleReceivedPerHop(uint256 hopIndex, uint256 minPrice, uint256 price);
    error V3TooMuchRequestedPerHop(uint256 hopIndex, uint256 minPrice, uint256 price);
    error V3HopPriceAndPathLengthMismatch();

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        if (amount0Delta <= 0 && amount1Delta <= 0) revert V3InvalidSwap(); // swaps entirely within 0-liquidity regions are not supported
        (, address payer, uint256[] memory minHopPriceX36, uint256 hopIndex) =
            abi.decode(data, (bytes, address, uint256[], uint256));
        bytes calldata path = data.toBytes(0);

        // because exact output swaps are executed in reverse order, in this case tokenOut is actually tokenIn
        (address tokenIn, uint24 fee, address tokenOut) = path.decodeFirstPool();

        if (computePoolAddress(tokenIn, tokenOut, fee) != msg.sender) revert V3InvalidCaller();

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0 ? (tokenIn < tokenOut, uint256(amount0Delta)) : (tokenOut < tokenIn, uint256(amount1Delta));

        if (isExactInput) {
            // Pay the pool (msg.sender)
            payOrPermit2Transfer(tokenIn, payer, msg.sender, amountToPay);
        } else {
            // either initiate the next swap or pay
            if (path.hasMultiplePools()) {
                // Per-hop price check for exact-output intermediate hops
                if (minHopPriceX36.length != 0) {
                    uint256 amountOut = uint256(-(amount0Delta > 0 ? amount1Delta : amount0Delta));
                    uint256 price = amountOut * Constants.PRICE_PRECISION / amountToPay;
                    uint256 minPrice = minHopPriceX36[hopIndex];
                    if (price < minPrice) revert V3TooMuchRequestedPerHop(hopIndex, minPrice, price);
                }
                // this is an intermediate step so the payer is actually this contract
                path = path.skipToken();
                _swap(
                    -amountToPay.toInt256(),
                    msg.sender,
                    path,
                    payer,
                    false,
                    minHopPriceX36,
                    hopIndex > 0 ? hopIndex - 1 : 0
                );
            } else {
                if (amountToPay > MaxInputAmount.get()) revert V3TooMuchRequested();
                // Per-hop price check for the first trading hop (last executed in exact-output)
                if (minHopPriceX36.length != 0) {
                    uint256 amountOut = uint256(-(amount0Delta > 0 ? amount1Delta : amount0Delta));
                    uint256 price = amountOut * Constants.PRICE_PRECISION / amountToPay;
                    uint256 minPrice = minHopPriceX36[hopIndex];
                    if (price < minPrice) revert V3TooMuchRequestedPerHop(hopIndex, minPrice, price);
                }
                // note that because exact output swaps are executed in reverse order, tokenOut is actually tokenIn
                payOrPermit2Transfer(tokenOut, payer, msg.sender, amountToPay);
            }
        }
    }

    /// @notice Performs a Uniswap v3 exact input swap
    /// @param recipient The recipient of the output tokens
    /// @param amountIn The amount of input tokens for the trade
    /// @param amountOutMinimum The minimum desired amount of output tokens
    /// @param path The path of the trade as a bytes string
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v3SwapExactInput(
        address recipient, //@audit right here we have the recipient 
        uint256 amountIn, //@audit right here we have the amountIn
        uint256 amountOutMinimum, //@audit right here we have the amountOutMinimum
        bytes calldata path, ///@audit right here we have the path
        address payer, //@audit right here we have the payer 
        uint256[] calldata minHopPriceX36 //@audit right here we have the minHopPricex96 
    ) internal {
        // Validate hop price array length
        // V3 path: token(20) + [fee(3) + token(20)] * numHops => path.length = (minHopPriceX36.length * 23) + 20
        if ( //@audit right here we checked that the minHopPricex36 length is not 0 
            minHopPriceX36.length != 0
                && path.length != (minHopPriceX36.length * Constants.NEXT_V3_POOL_OFFSET) + Constants.ADDR_SIZE
        ) revert V3HopPriceAndPathLengthMismatch(); //@audit right here we checked that the minHopPricex36 != 0 

        //@audit right here we also checked that the path.length != minHopPricex36.length + NEXT_V3_POOL_OFFSET

        // use amountIn == ActionConstants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        // Note: balanceOf includes tokens any third party sent to the router, so a donation enlarges the trade.
        // The larger trade earns a worse average rate, which can trip minHopPriceX36 and revert the route, and SWEEP
        // takes an arbitrary recipient so the donation is recoverable.
        if (amountIn == ActionConstants.CONTRACT_BALANCE) { //@audit right here we checked the amountin == contract_balance right here 
            address tokenIn = path.decodeFirstToken();  //@audit right we want to decode the first token 
             //@audit right here we decoded the the first token()
            amountIn = ERC20(tokenIn).balanceOf(address(this)); //@audit right here we got the balanceOf(address(this))
        }

        uint256 amountOut; //@audit right here too we also have the amountOut 
        uint256 hopIndex; //@audit right here we have the hopIndex
        uint256 previousAmountIn = amountIn; //@audit right here also we have the previousAmountIn
        uint256[] memory emptyHopPrice = new uint256[](0); //@audit right here we have the emptyHopPrice 
        while (true) { //@audit right here we have while true 
            bool hasMultiplePools = path.hasMultiplePools(); //@audit does it have multiple pool

            // the outputs of prior swaps become the inputs to subsequent ones
            (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) = _swap( //@audit right here we swapped the 
                amountIn.toInt256(), //@audit right here we have the amountIn
                hasMultiplePools ? address(this) : recipient, // for intermediate swaps, this contract custodies
                path.getFirstPool(), // only the first pool is needed
                payer, // for intermediate swaps, this contract custodies 
                true, //@audit right here we have the true 
                emptyHopPrice, // exact-in callbacks don't need price checks
                0
            );

            //@audit right here if it is zeroForOne -> amount1Delta
            amountIn = uint256(-(zeroForOne ? amount1Delta : amount0Delta)); //@audit right here if it is zeroForOne

            //@audit right here we have it to be amount1Delta we have the amountIn

            // Per-hop price check for exact-input
            if (minHopPriceX36.length != 0) { //@audit right here if the minHopPricex36
                uint256 price = amountIn * Constants.PRICE_PRECISION / previousAmountIn;  //@audit right here we compared the 2 amount in to check these values 
                //@audit right here we checked with the price yes or yes 
                uint256 minPrice = minHopPriceX36[hopIndex]; //@audit right here and then we got the minPrice 
                if (price < minPrice) revert V3TooLittleReceivedPerHop(hopIndex, minPrice, price); //@audit right here if the
                //@audit right here if the price < minPrice then we revert away 
            }

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this); //@audit right here if it has multiple pools payer is address(this)
                path = path.skipToken(); // -> we just picked the next tokens 
                
                previousAmountIn = amountIn;        //@audit right here we set the previous amount in 
                hopIndex++; //@audit we increased the hopIndex++ 
            } else { //@audit right here we set the amountOut = amountIn and then we break 
                amountOut = amountIn; //@audit right here we set the amountOut as the amountIn and then we break lol
                break;
            }
        }

        if (amountOut < amountOutMinimum) revert V3TooLittleReceived(); //@audit right here we checked that if the amountOut < amountOutminimum and then we reverted 
    }

    /// @notice Performs a Uniswap v3 exact output swap
    /// @param recipient The recipient of the output tokens
    /// @param amountOut The amount of output tokens to receive for the trade
    /// @param amountInMaximum The maximum desired amount of input tokens
    /// @param path The path of the trade as a bytes string
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v3SwapExactOutput(
        address recipient,
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes calldata path,
        address payer,
        uint256[] calldata minHopPriceX36
    ) internal {
        // Validate hop price array length
        // V3 path: token(20) + [fee(3) + token(20)] * numHops => path.length = (minHopPriceX36.length * 23) + 20
        if (
            minHopPriceX36.length != 0
                && path.length != (minHopPriceX36.length * Constants.NEXT_V3_POOL_OFFSET) + Constants.ADDR_SIZE
        ) revert V3HopPriceAndPathLengthMismatch();

        // Convert calldata to memory for abi.encode in _swap
        uint256[] memory minHopPriceX36Memory = minHopPriceX36;

        MaxInputAmount.set(amountInMaximum);

        // For exact-output, the first _swap handles the LAST trading hop.
        // Trading direction: hop 0 (A->B), hop 1 (B->C), ...
        // Execution: last hop first, then callbacks handle earlier hops.
        // So start hopIndex at minHopPriceX36Memory.length - 1 and decrement in callbacks.
        uint256 startHopIndex = minHopPriceX36Memory.length > 0 ? minHopPriceX36Memory.length - 1 : 0;

        (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) =
            _swap(-amountOut.toInt256(), recipient, path, payer, false, minHopPriceX36Memory, startHopIndex);

        uint256 amountOutReceived = zeroForOne ? uint256(-amount1Delta) : uint256(-amount0Delta);

        if (amountOutReceived != amountOut) revert V3InvalidAmountOut();

        MaxInputAmount.set(0);
    }

    /// @dev Performs a single swap for both exactIn and exactOut
    /// For exactIn, `amount` is `amountIn`. For exactOut, `amount` is `-amountOut`
    function _swap(
        int256 amount,
        address recipient,
        bytes calldata path,
        address payer,
        bool isExactIn,
        uint256[] memory minHopPriceX36,
        uint256 hopIndex
    ) private returns (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) {
        (address tokenIn, uint24 fee, address tokenOut) = path.decodeFirstPool();

        zeroForOne = isExactIn ? tokenIn < tokenOut : tokenOut < tokenIn;

        (amount0Delta, amount1Delta) = IUniswapV3Pool(computePoolAddress(tokenIn, tokenOut, fee))
            .swap(
                recipient,
                zeroForOne,
                amount,
                (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1),
                abi.encode(path, payer, minHopPriceX36, hopIndex)
            );
    }

    function computePoolAddress(address tokenA, address tokenB, uint24 fee) private view returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            UNISWAP_V3_FACTORY,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            UNISWAP_V3_POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
