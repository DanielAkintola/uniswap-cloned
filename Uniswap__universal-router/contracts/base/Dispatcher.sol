// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {V2SwapRouter} from '../modules/uniswap/v2/V2SwapRouter.sol';
import {V3SwapRouter} from '../modules/uniswap/v3/V3SwapRouter.sol';
import {V4SwapRouter} from '../modules/uniswap/v4/V4SwapRouter.sol';
import {BytesLib} from '../modules/uniswap/v3/BytesLib.sol';
import {Payments} from '../modules/Payments.sol';
import {Constants} from '../libraries/Constants.sol';
import {NestedUnlock} from '../libraries/NestedUnlock.sol';
import {PaymentsImmutables} from '../modules/PaymentsImmutables.sol';
import {V3ToV4Migrator} from '../modules/V3ToV4Migrator.sol';
import {Commands} from '../libraries/Commands.sol';
import {ResolvedAmount} from '../libraries/ResolvedAmount.sol';
import {IAmountResolver} from '../interfaces/IAmountResolver.sol';
import {IV4FeeAdapter} from '../interfaces/external/IV4FeeAdapter.sol';
import {IV3FeeAdapter} from '../interfaces/external/IV3FeeAdapter.sol';
import {IUniswapV3Factory} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import {Lock} from './Lock.sol';
import {ERC20} from 'solmate/src/tokens/ERC20.sol';
import {IAllowanceTransfer} from 'permit2/src/interfaces/IAllowanceTransfer.sol';
import {SafeCast160} from 'permit2/src/libraries/SafeCast160.sol';
import {CalldataDecoder} from '@uniswap/v4-periphery/src/libraries/CalldataDecoder.sol';
import {PoolKey} from '@uniswap/v4-core/src/types/PoolKey.sol';
import {IPoolManager} from '@uniswap/v4-core/src/interfaces/IPoolManager.sol';
import {TransientStateLibrary} from '@uniswap/v4-core/src/libraries/TransientStateLibrary.sol';
import {ChainedActions} from '../modules/ChainedActions.sol';

/// @title Decodes and Executes Commands
/// @notice Called by the UniversalRouter contract to efficiently decode and execute a singular command
abstract contract Dispatcher is
    Payments, //@audit right here we have the payments here  
    V2SwapRouter, //@audit right here we have the v2swapRouter too 
    V3SwapRouter, //@audit right here we have the v3swapRouter too
    V4SwapRouter, //@audit right here 
    V3ToV4Migrator, // @audit right here we have the v3-> v4 migrator
    Lock, // @audit right herre we have the lock too
    ChainedActions
{
    using BytesLib for bytes;
    using CalldataDecoder for bytes;
    using TransientStateLibrary for IPoolManager;

    error InvalidCommandType(uint256 commandType);
    error BalanceTooLow();
    /// @notice Thrown when a route reaches V4_SWAP inside a foreign PoolManager unlock without opting in
    error NestedExecutionNotPermitted();

    /// @notice Executes encoded commands along with provided inputs.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    function execute(bytes calldata commands, bytes[] calldata inputs) external payable virtual;

    /// @notice Public view function to be used instead of msg.sender, as the contract performs self-reentrancy and at
    /// times msg.sender == address(this). Instead msgSender() returns the initiator of the lock
    /// @dev overrides BaseActionsRouter.msgSender in V4Router
    function msgSender() public view override returns (address) {
        return _getLocker(); 
    }

    /// @notice Decodes and executes the given command with the given inputs
    /// @param commandType The command type to execute
    /// @param inputs The inputs to execute the command with
    /// @dev 2 masks are used to enable use of a nested-if statement in execution for efficiency reasons
    /// @return success True on success of the command, false on failure
    /// @return output The outputs or error messages, if any, from the command
    [length:actualdata]
    function dispatch(bytes1 commandType, bytes calldata inputs) internal returns (bool success, bytes memory output) { //@audit right here we have a success and then an output too 
        uint256 command = uint8(commandType & Commands.COMMAND_TYPE_MASK); //@audit right here we anded it with the command_type_mask
        //@audit right here we have the uint8 of that 
        //@audit right here we masked the 
        success = true; //@audit right here we set the success to be true right away 

        // 0x00 <= command < 0x21 //@audit right here 
        if (command < Commands.EXECUTE_SUB_PLAN) { //@audit right here we want to execute the sub plan right here 
            // 0x00 <= command < 0x10
            if (command < Commands.V4_SWAP) {  //@audit right if it is of type V4_SWAP
                // 0x00 <= command < 0x08
                if (command < Commands.V2_SWAP_EXACT_IN) {  //@audit right here we checked if the V2_SWAP_EXACT_IN
                    if (command == Commands.V3_SWAP_EXACT_IN) {  //@audit right here we checked if the v3
                        checkInputLength(inputs, 0xc0); //@audit right here we have the checkInputLength here 
                        // equivalent: abi.decode(inputs, (address, uint256, uint256, bytes, bool, uint256[]))
                        
                        address recipient; //@audit right here we have the recipient too
                        uint256 amountIn; //@audit right here we we have the amountIn
                        uint256 amountOutMin; //@audit right here we also have the amountOutMin
                        bool payerIsUser; //@audit right here we also have the payerIsUser 

                        assembly {  //@audit right here we have the calldataload(inputs.offset)
                            recipient := calldataload(inputs.offset) //@audit right here we have the inputs.offset right here 
                            amountIn := calldataload(add(inputs.offset, 0x20)) //@audit right here 
                            amountOutMin := calldataload(add(inputs.offset, 0x40)) //@audit right here we got the amountOutMin
                            // 0x60 offset is the path, decoded below //@audit right here we have this guy contains the path 

                            //@audit right here we have the payerIsUser too here 
                            payerIsUser := calldataload(add(inputs.offset, 0x80)) //@audit right here we have the payerIsUser 
                        } //@audit right here to load it in to payerIsUser 

                        //@audit right here we have to bytes 

                        bytes calldata path = inputs.toBytes(3); //@note will check what's going on here //@audit right here we have the inputs.toBytes(3);
                        uint256[] calldata minHopPriceX36 = inputs.toUint256Array(5); //@audit right here we also have to an array right here with the 5 passed in 
                        address payer = payerIsUser ? msgSender() : address(this); //@audit right here then we checked if the payerIsUser or else we returned the msg.sender and address(this)
                       
                        v3SwapExactInput(  //@audit right here is the dispatcher that does this 
                            //@audit right here we have the v3SwapExactInput 
                            _mapRecipient(recipient), //@audit right here we want to mapRecipient 
                            ResolvedAmount.map(amountIn), //@audit right here too we want to map the amount in
                            amountOutMin,
                            path,
                            payer,
                            minHopPriceX36
                        );
                    } else if (command == Commands.V3_SWAP_EXACT_OUT) { //@audit right here we want to check if the 
                        checkInputLength(inputs, 0xc0); //@audit right here we checked the length of the input to be 0xc0 why??
                       
                       
                        // equivalent: abi.decode(inputs, (address, uint256, uint256, bytes, bool, uint256[]))
                        address recipient; //@audit right here we have the recipient 
                        uint256 amountOut; //@audit right here we have the amountOut too
                        uint256 amountInMax; //@audit right here we now have the amountInMax 
                        bool payerIsUser; //@audit right here we have the payerIsUser 


                        assembly {
                            recipient := calldataload(inputs.offset) //@audit right here we got the calldataload(input.offset)
                            amountOut := calldataload(add(inputs.offset, 0x20)) //@audit right here we now added the inputs.offset + 0x20
                            amountInMax := calldataload(add(inputs.offset, 0x40)) //@audit right here too we have the inputs.offset + 0x40
                            // 0x60 offset is the path, decoded below
                            payerIsUser := calldataload(add(inputs.offset, 0x80)) //@audit right here we added the offset + 0x80, 
                        }

                        bytes calldata path = inputs.toBytes(3); //@audit right here we have the path given the bytes right here 
                        uint256[] calldata minHopPriceX36 = inputs.toUint256Array(5); //@audit right here we also have the minHopPricex36
                        address payer = payerIsUser ? msgSender() : address(this); //@audit right here we also have the payer we checked if the payerIsUser -> msg.sender or address(this)
                        //@audit right here we have the payer 

                        v3SwapExactOutput( //@audit right here we want to swapExactOutput 
                            _mapRecipient(recipient), //@audit right here we got the v3SwapExactOutput too
                            ResolvedAmount.map(amountOut),  //@audit right here we have ResolvedAmount.Map(amountOut)
                            amountInMax, //@audit right here we have the amountInMax
                            path, //@audit right here we have the path
                            payer, //@audit right here we have the payer 
                            minHopPriceX36
                        );
                    } else if (command == Commands.PERMIT2_TRANSFER_FROM) { //@audit right here we checked if the command == commands.Permit2_trnasfer_from
                        checkInputLength(inputs, 0x60); //@audit right here we want to check the input lengths 

                        // equivalent: abi.decode(inputs, (address, address, uint160))
                        address token; //@audit right here we have the token 
                        address recipient; //@audit right here we also have the guy that should get the token 
                        uint160 amount; //@audit we have the token, recipient and the amount

                        assembly { //@audit right here we read the 
                            token := calldataload(inputs.offset) //@audit right here we have the input.offset here 
                            recipient := calldataload(add(inputs.offset, 0x20)) //@audit right we have the recipient and the amount 
                            amount := calldataload(add(inputs.offset, 0x40)) //@audit right here we have the amount 
                        }
                        
                        permit2TransferFrom(//@audit right here we want to permit2TransferFROM
                            token, //@audit right here is the token 
                            msgSender(), //@audit right here we also have the msgSender()
                            _mapRecipient(recipient), //@audit right here we also have the map the recipient too 
                            SafeCast160.toUint160(ResolvedAmount.map(amount)) //@audit right here we have the resolvedAmount 
                        ); //@audit right here we want to SafeCast160
                    } else if (command == Commands.PERMIT2_PERMIT_BATCH) { //@audit right here we want to permit2_permit_batch
                            //@audit right here we got the permitBatch here 
                        IAllowanceTransfer.PermitBatch calldata permitBatch = decodePermitBatch(inputs); //@audit right here we want to 
                        bytes calldata data = inputs.toBytes(1);  //@audit right here we have the toBytes(1)
                        //@audit right here we want to have the inputs.toBytes(1 )
                        
                        (success, output) = address(PERMIT2) //@audit right here we have the permit2
                            .call(
                                abi.encodeWithSignature( //@audit we then call to 
                                    'permit(address,((address,uint160,uint48,uint48)[],address,uint256),bytes)',
                                    msgSender(),
                                    permitBatch,
                                    data
                                )
                            );
                    } else if (command == Commands.SWEEP) {
                        checkInputLength(inputs, 0x60); //@audit right here we have the check the input lengths 
                        // equivalent:  abi.decode(inputs, (address, address, uint256))
                        address token;
                        address recipient;
                        uint256 amountMin;
                        assembly {
                            token := calldataload(inputs.offset)
                            recipient := calldataload(add(inputs.offset, 0x20))
                            amountMin := calldataload(add(inputs.offset, 0x40))
                        }
                        // An adapter unwraps on arrival, so the router only ever holds the underlying.
                        // Sweeping the adapter would read an always-zero balance and strand the underlying.
                        // ETH short-circuits: Constants.ETH is address(0), which is never an adapter, so
                        // the lookup would be both wasted and reliant on the factory returning zero for it.
                        if (token != Constants.ETH && address(PERMISSIONS_ADAPTER_FACTORY) != address(0)) {
                            address underlying = PERMISSIONS_ADAPTER_FACTORY.verifiedPermissionsAdapterOf(token); //@audit right here we want to verify the permissions of adpater of token 
                            if (underlying != address(0)) token = underlying; //@audit right here if the underlying is not address(0) then we set the token to the underlying 
                        }

                        Payments.sweep(token, _mapRecipient(recipient), amountMin); //@audit right here then we 
                    } else if (command == Commands.TRANSFER) {
                        checkInputLength(inputs, 0x60); //@audit right here we have the lneth check 
                        // equivalent:  abi.decode(inputs, (address, address, uint256))
                        address token;
                        address recipient;
                        uint256 value;

                        assembly { //@audit right here we have these calldataload(inputs.offset)
                            token := calldataload(inputs.offset)
                            recipient := calldataload(add(inputs.offset, 0x20))
                            value := calldataload(add(inputs.offset, 0x40))
                        }

                        Payments.pay(token, _mapRecipient(recipient), ResolvedAmount.map(value));
                    } else if (command == Commands.PAY_PORTION) {
                        checkInputLength(inputs, 0x60); //@audit right here we checked the inputs's length from here 
                        // equivalent:  abi.decode(inputs, (address, address, uint256))
                        address token; //@audit here we have the token
                        address recipient; //@audit here too we have the recipient 
                        uint256 bips; //@audit here too we have the bips

                        assembly {
                            token := calldataload(inputs.offset)
                            recipient := calldataload(add(inputs.offset, 0x20))
                            bips := calldataload(add(inputs.offset, 0x40))
                        }

                        Payments.payPortion(token, _mapRecipient(recipient), bips); //@audit right here we mapped the recipient given the recipient with those bips and the token given from there 
                    } else if (command == Commands.PAY_PORTION_FULL_PRECISION) {
                        checkInputLength(inputs, 0x60); //@audit right here we have the minimum data length to deal with 
                        // equivalent:  abi.decode(inputs, (address, address, uint256))
                        
                        address token; //@audit right here we also have the token 
                        address recipient; //@audit right here too we have the recipient 
                        uint256 portion;
                        assembly {
                            token := calldataload(inputs.offset)
                            recipient := calldataload(add(inputs.offset, 0x20))
                            portion := calldataload(add(inputs.offset, 0x40))
                        }

                        Payments.payPortionFullPrecision(token, _mapRecipient(recipient), portion); //@audit right here we justhave the 
                    }
                } else {  //@audit right here we got the exact in method performed 
                    // 0x08 <= command < 0x10
                    if (command == Commands.V2_SWAP_EXACT_IN) { 
                        checkInputLength(inputs, 0xc0); 

                        // equivalent: abi.decode(inputs, (address, uint256, uint256, address[], bool, uint256[]))
                        address recipient; //@audit right here we have the recipient 
                        uint256 amountIn; //@audit right here we have the amountIn
                        uint256 amountOutMin; //@audit right here we have the amountOutMin
                        bool payerIsUser; //@audit right here we have the payerIsUser 

                        assembly {
                            recipient := calldataload(inputs.offset) //@note right here we 
                            amountIn := calldataload(add(inputs.offset, 0x20)) //@audit right here we loaded the amountin 
                            amountOutMin := calldataload(add(inputs.offset, 0x40)) //@audit right here we took the amountOutMin
                            // 0x60 offset is the path, decoded below
                            payerIsUser := calldataload(add(inputs.offset, 0x80)) //@audit right here we got the payerIsUser 
                        }


                        address[] calldata path = inputs.toAddressArray(3); //@audit right here we got the inputs 
                        uint256[] calldata minHopPriceX36 = inputs.toUint256Array(5); //@audit right here we have the minHopPricex36 
                        address payer = payerIsUser ? msgSender() : address(this); //@audit right here if the  payer 

                        v2SwapExactInput( //@audit right here we have the v2SwapExactinput 
                            _mapRecipient(recipient), //@audit right here we map the recipient 
                            ResolvedAmount.map(amountIn), //@audit right here we have the ResolvedAmount.map(AmountIn)
                            amountOutMin, //@audit right here we have the amountOutMin
                            path, //@audit right here we have the path too
                            payer, //@audit right here we also have the payer 
                            minHopPriceX36 //@audit right here we also have the minHopPricex36
                        );
                    } else if (command == Commands.V2_SWAP_EXACT_OUT) {
                        checkInputLength(inputs, 0xc0); //@audit right here we checked the inputs length right here and we checked if the input 
                        // equivalent: abi.decode(inputs, (address, uint256, uint256, address[], bool, uint256[]))
                      
                        address recipient; //@audit right here we have the recipient 
                        uint256 amountOut; //@audit right here we have the amountOut 
                        uint256 amountInMax; //@audit right here we have the amountInMax
                        bool payerIsUser; //@audit right here we have payerIsUser 

                        assembly { //@audit right here we have the inputs.offset 
                            recipient := calldataload(inputs.offset)
                            amountOut := calldataload(add(inputs.offset, 0x20)) //@audit right here we have the amountOut
                            amountInMax := calldataload(add(inputs.offset, 0x40)) //@audit right here we have the input.offset with the 0x40 
                            
                            // 0x60 offset is the path, decoded below
                            payerIsUser := calldataload(add(inputs.offset, 0x80)) //@audit right here we also performed that and attached it with 
                            //@audit right here we want to perform the payerIsUser shit 
                        }

                        address[] calldata path = inputs.toAddressArray(3); //@audit right here we have the inputs to address array
                        uint256[] calldata minHopPriceX36 = inputs.toUint256Array(5); //@audit right here too we have 
                        address payer = payerIsUser ? msgSender() : address(this); //@audit when we check the payerIsUser ? msg.sender : address(this)
                       
                        v2SwapExactOutput( //@audit right here we have the v2SwapExactOutput
                            _mapRecipient(recipient), //@audit right here we want to map the recipient 
                            ResolvedAmount.map(amountOut), //@audit right here we resolvedAmount.map(AmountOut)
                            amountInMax, //@audit right here too we have the amountInMax
                            path, //@audit right here we have the path too
                            payer, //@audit right here too we have the payer
                            minHopPriceX36 //@audit right here we have the minHopPricex36
                        );
                    } else if (command == Commands.PERMIT2_PERMIT) {
                        checkInputLength(inputs, 0xe0);
                        // equivalent: abi.decode(inputs, (IAllowanceTransfer.PermitSingle, bytes))
                        IAllowanceTransfer.PermitSingle calldata permitSingle;
                        assembly {
                            permitSingle := inputs.offset
                        }
                        bytes calldata data = inputs.toBytes(6); // PermitSingle takes first 6 slots (0..5)
                        (success, output) = address(PERMIT2)
                            .call(
                                abi.encodeWithSignature(
                                    'permit(address,((address,uint160,uint48,uint48),address,uint256),bytes)',
                                    msgSender(),
                                    permitSingle,
                                    data
                                )
                            );
                    } else if (command == Commands.WRAP_ETH) { //@audit right here we have the WRAP_ETH from here 
                        checkInputLength(inputs, 0x40); //@audit right here we have to check the input length with the 0x40
                        // equivalent: abi.decode(inputs, (address, uint256))
                        
                        address recipient; //@audit right here we also have the recipient 
                        uint256 amount; //@audit right here we also have the amount we are working with 
                        assembly { //@audit right here we have the calldata load the inputs.offset from here 
                            recipient := calldataload(inputs.offset)
                            amount := calldataload(add(inputs.offset, 0x20)) //@audit right here too we have the add -> input.offset with the 0x20
                        }
                        //@audit right here we have the system called in from there too
                        //@audit right here we have the mapRecipient shitty guy from here 

                        //@audit right here we want to wrapETH  
                        Payments.wrapETH(_mapRecipient(recipient), ResolvedAmount.map(amount)); //@audit right here we have the resolved amount guy here too 
                    } else if (command == Commands.UNWRAP_WETH) { //@audit rif
                        checkInputLength(inputs, 0x40); //@audit right here we have the 
                        // equivalent: abi.decode(inputs, (address, uint256))
                        address recipient;
                        uint256 amountMin; //@audit right here we got the amountMin from here 
                       
                        assembly {
                            recipient := calldataload(inputs.offset) //@audit right here we got the offset from there to get the recipient 
                            amountMin := calldataload(add(inputs.offset, 0x20)) //@audit right here we added input.offset and the 0x20 too 
                        }
                        //@audit right here we want to unwrap the weth with the recipient and the amountMin
                        Payments.unwrapWETH9(_mapRecipient(recipient), amountMin); //@audit right here we want to specify the minimum amount to unwrap -> note here we didn't specify the Resolved.amount
                    } else if (command == Commands.PERMIT2_TRANSFER_FROM_BATCH) { //@audit right here we want to perform a command check right here 
                        IAllowanceTransfer.AllowanceTransferDetails[] calldata batchDetails; //@audit right here we have the batchDetails lol
                        (uint256 length, uint256 offset) = inputs.toLengthOffset(0, 0x80); //@audit right here we have the toLengthOffset from here with the 0x80

                        assembly {
                            batchDetails.length := length //@audit right here we got the length from here 
                            batchDetails.offset := offset //@audit right here too we got the offset too
                        } //@audit right here we got the length and the offset and set the pointer for those too two 

                        permit2TransferFrom(batchDetails, msgSender());
                    } else if (command == Commands.BALANCE_CHECK_ERC20) {
                        checkInputLength(inputs, 0x60);
                        // equivalent: abi.decode(inputs, (address, address, uint256))
                        address owner;
                        address token;
                        uint256 minBalance;
                        assembly {
                            owner := calldataload(inputs.offset)
                            token := calldataload(add(inputs.offset, 0x20))
                            minBalance := calldataload(add(inputs.offset, 0x40))
                        }
                        success = (ERC20(token).balanceOf(owner) >= minBalance);
                        if (!success) output = abi.encodePacked(BalanceTooLow.selector);
                    } else if (command == Commands.UNWRAP_WETH_EXACT) {
                        checkInputLength(inputs, 0x40); //@audit right here we checked the inputs length from here too 
                        // equivalent: abi.decode(inputs, (address, uint256))
                        address recipient; //@audit right here we have the recipient 
                        uint256 amount; //@audit right here amount too 
                        assembly {
                            recipient := calldataload(inputs.offset)
                            amount := calldataload(add(inputs.offset, 0x20))
                        }
                        Payments.unwrapWETH9Exact(_mapRecipient(recipient), ResolvedAmount.map(amount));
                    }
                }
            } else {
                // 0x10 <= command < 0x21
                if (command == Commands.V4_SWAP) { //@audit right here 
                    // If the PoolManager is already unlocked, this contract is executing inside another
                    // contract's unlock callback. Opening a new lock via _executeActions would revert with
                    // AlreadyUnlocked, so instead run the v4 actions within the existing lock.
                    //@audit right here within the existing lock 
                    if (poolManager.isUnlocked()) { //@audit right here if the poolmanager is unlocked 
                        // Nesting shares the router's delta account with every other call in this
                        // unlock, so it runs only when the caller explicitly opted in via executeNested.
                        //@audit right here if nested is not allowed then we revert 
                                     if (!NestedUnlock.isPermitted()) revert NestedExecutionNotPermitted(); //@audit right here we checked against nested execution right here 
                        // The v4 swap parameter decoders (v4-periphery) bound every struct and member offset
                        // against the input length via abi.decode, so decoding directly from this calldata
                        // slice cannot read past inputs[i].length. Coverage: V4NestedMemberSmuggle.t.sol and
                        // V4NestedUnlockCalldataSmuggling.t.sol.
                        (bytes calldata actions, bytes[] calldata params) = inputs.decodeActionsRouterParams(); //@audit right here we want to decode the actions router params 
                        _executeActionsWithoutUnlock(actions, params); //@audit right here execute actions without unlock with those params right here and there 
                        //@note so we want to support multiple actions together in the system 
                    } else { 
                        //@audit right here we want to execute the actions too 
                        //@audit right here we want to execute the operations
                        // pass the calldata provided to V4SwapRouter._executeActions (defined in BaseActionsRouter)
                        _executeActions(inputs); //@audit right here we want to execute the actions with those inputs here too 
                        //@audit right here we want to execute those actions with those inputs too 
                        //@audit right here with those inputs 
                    }

                    // This contract MUST be approved to spend the token since its going to be doing the call on the position manager
                } else if (command == Commands.V3_POSITION_MANAGER_PERMIT) {
                    //@audit right here we want to check the v3 permit call with those inputs 
                    _checkV3PermitCall(inputs); //@audit right here we checked the checkV3PermitCall with the inputs 
                    (success, output) = address(V3_POSITION_MANAGER).call(inputs); //@audit right here we did that here  and then we returned success and output 
                } else if (command == Commands.V3_POSITION_MANAGER_CALL) { 
                    _checkV3PositionManagerCall(inputs, msgSender()); //@audit right here so we can perfom
                    (success, output) = address(V3_POSITION_MANAGER).call(inputs);  //@audit right here we called the inputs 

                    //@audit right here we called the v3_PM and then call those with the inputs 
                    //@audit right here we have the success and the output too 
                } else if (command == Commands.V4_INITIALIZE_POOL) {
                    checkInputLength(inputs, 0xc0);
                    PoolKey calldata poolKey; //@audit right here wa have the poolkey
                    uint160 sqrtPriceX96;
                    assembly {
                        poolKey := inputs.offset
                        sqrtPriceX96 := calldataload(add(inputs.offset, 0xa0))
                    }

                    (success, output) = //@audit right here we have the poolManager with those call initialize 
                        address(poolManager).call(abi.encodeCall(IPoolManager.initialize, (poolKey, sqrtPriceX96)));
                } else if (command == Commands.V4_POSITION_MANAGER_CALL) {
                    // should only call modifyLiquidities() to mint
                    _checkV4PositionManagerCall(inputs); //@audit right here we have to check the check V4 POSITION manager call
                    (success, output) = address(V4_POSITION_MANAGER).call{value: address(this).balance}(inputs); //@audit right here we have the PPM
                } else if (command == Commands.RESOLVE) {
                    checkInputLength(inputs, 0x40); //@audit right here we got the bytes 
                    // equivalent: abi.decode(inputs, (address, bytes))
                    address resolver;

                    assembly { //@audit right here we got the resolver 
                        resolver := calldataload(inputs.offset)
                    }

                    bytes calldata context = inputs.toBytes(1); //@audit right here we want to get the context of the inputs with the bytes 
                    success = _resolve(resolver, context); //@audit right here we want to resolve with the resolver ant the context
                } else if (command == Commands.V4_PROTOCOL_FEE_UPDATE) {
                    checkInputLength(inputs, 0xa0); //@audit right here we have the 0x
                    // equivalent: abi.decode(inputs, (PoolKey))
                    PoolKey calldata poolKey; //@audit right here we have the protocol fee update system here too 
                    assembly { //@audit right here we have the poolKey and the inputs.offset 
                        poolKey := inputs.offset
                    }

                    // New pools initialize with no protocol fee; governance's fee adapter is registered on the
                    // PoolManager as its protocolFeeController and exposes a permissionless poke that pushes the
                    // resolved fee into pool state. Reading the controller onchain means the router never holds an
                    // adapter address and follows any future controller change.
                    (success, output) = poolManager.protocolFeeController() //@audit right here we spoke to the protocol fee controller to trigger the fee update too given the poolKey
                        .call(abi.encodeCall(IV4FeeAdapter.triggerFeeUpdate, (poolKey)));
                } else if (command == Commands.V3_PROTOCOL_FEE_UPDATE) {
                    checkInputLength(inputs, 0x20);
                  
                    // equivalent: abi.decode(inputs, (address))
                    address pool;
                   
                    assembly { //@audit right here we have the pool right here 
                        pool := calldataload(inputs.offset)
                    }

                    // The v3 fee adapter owns the v3 factory; read it onchain and poke it for this pool.
                    (success, output) = IUniswapV3Factory(UNISWAP_V3_FACTORY).owner()
                        .call(abi.encodeCall(IV3FeeAdapter.triggerFeeUpdate, (pool))); //@audit right here we have the owner then we call the 
                
                } else { //@audit right here we reverted right away from there 
                    // placeholder area for commands 0x18-0x20
                    revert InvalidCommandType(command);
                }
            }
        
        } else if (command < Commands.ACROSS_V4_DEPOSIT_V3) { //@audit right here if the command < ACROSS_V4_DEPOSIT_V3
            // 0x21 <= command
            if (command == Commands.EXECUTE_SUB_PLAN) { //@audit right here we have to check if it is EXECUTE_SUB_PLAN  
                //@audit right here we want to decode the commands anf the inputs
                //@audit right here we want to decode the inputs to give us commands and inputs 

                //@audit right here then we decoded the commands and inputs 
                (bytes calldata _commands, bytes[] calldata _inputs) = inputs.decodeCommandsAndInputs(); //@audit right here we decoded the commands and their inputs 
                (success, output) = (address(this)).call(abi.encodeCall(Dispatcher.execute, (_commands, _inputs))); //@audit right here we performed the call on it 
                
                //@audit right here we want to call execute with the commands and the inputs address(this).call()
                //@audit right here and then we also performed the encodeCall(execute, commands and the inputs)
                //@audit right here we performed the success and the output 

                // The nested-execution gate is a consent check, not a route failure: FLAG_ALLOW_REVERT on the
                // sub-plan must not turn it into a silent skip that leaves the route's input in the router.
                if (!success && output.length == 4 && bytes4(output) == NestedExecutionNotPermitted.selector) {  //@audit right here we check if it is successful and the output and the 
                   //@audit if it is not successful and the output.length is just 4 and the bytes4(output) == NestedExecutionNotPermitted.selector
                    revert NestedExecutionNotPermitted(); //@audit right here if it is not success ful and the output.length is 4 and the bytes4(output)
                } //@audit right here we have the NestedExecutionNotPermitted from here 

            } else {  //@audit right here we have this guy out here 
                // placeholder area for commands 0x22-0x3f
                revert InvalidCommandType(command); //@audit we revert the InvalidCommandType(command)
            }
        } else {         //@audit right here if the command == ACROSS_V4_DEPOSIT_V3    
            if (command == Commands.ACROSS_V4_DEPOSIT_V3) { //@audit right here we across_v4_deposit_v3
                _acrossV4DepositV3(inputs);   //@audit we have the acrossV4DepositV3 //@audit if the command also is to 
            } else {
                // placeholder area for commands 0x41-0x5f
                revert InvalidCommandType(command);  //@audit right here we have the InvalidCommandType
            } 
        }
    }

    /// @dev Reverts if an input cannot contain the complete static ABI head consumed by a command.
    function checkInputLength(bytes calldata input, uint256 minimumLength) private pure {
        //@audit right here we checked if the input's length and the minimumlength then we revert the fuck away 
        if (input.length < minimumLength) revert CalldataDecoder.SliceOutOfBounds(); //@audit right here we checked the input.length < minimumLenght
        //@audit right here we checked if the input.length then we revert 
    } // @audit right here we checked if the input.length < minimumLength and then we revert 

    /// @notice Performs a bounded staticcall to a resolver and writes the result to the transient
    /// ResolvedAmount register for a later command to consume via Constants.USE_RESOLVED_AMOUNT.
    /// @dev The call is read-only (staticcall) so it cannot mutate state or reenter. At most one word
    /// of returndata is copied, so a return bomb costs the resolver gas and nothing else. A resolver
    /// that reverts, returns fewer than 32 bytes, or returns zero fails the command, composing with
    /// FLAG_ALLOW_REVERT like the other call-based commands: zero is not an amount any command can act
    /// on, and the v4 swap helpers would read it as OPEN_DELTA. Every failure clears the register, so
    /// no later command can consume a value this RESOLVE did not produce. A failure inside a sub-plan that
    /// then reverts is undone with the rest of the sub-plan, so the earlier value returns as if it never ran.
    function _resolve(address resolver, bytes calldata context) private returns (bool ok) { //@audit right here we have the bool ok 
        bytes memory callData = abi.encodeWithSelector(IAmountResolver.resolveAmount.selector, context); //@audit right herre we want to encodewith selector the resolveAmount.selector and the context 
        //@audit we have the calldata to resolve the amount here 
        uint256 result; //@audit right here we have the result
        
        assembly ('memory-safe') { //@audit right here we resolved it right away from here 
            ok := staticcall(gas(), resolver, add(callData, 0x20), mload(callData), 0, 0x20) //@audit right here we have this 
            // the copied word only means something after a successful call that returned a full word
            result := mul(mload(0), and(ok, gt(returndatasize(), 0x1f)))
            //@audit right here we asking that result is not zero
            ok := iszero(iszero(result)) //@audit right here we rewrite the ok if it is zero or it is zero
        } //@audit right here we have various commands that can be executed within that system to it makes a whole lot of sense 

        //@audit right here we have the resolver gotten from here 
        ResolvedAmount.set(result); //@audit we set the result, we have the 
    }

    /// @dev Decodes a Permit2 batch after validating its dynamic details array against the input bounds.
    function decodePermitBatch(bytes calldata input)
        private
        pure
        returns (IAllowanceTransfer.PermitBatch calldata permitBatch)
    {
        // PermitBatch has a three-word head: details offset, spender, and signature deadline.
        checkInputLength(input, 0x60);

        assembly ('memory-safe') {
            let inputLength := input.length
            let permitBatchOffset := calldataload(input.offset)

            // The PermitBatch head must be contained in the input.
            if gt(permitBatchOffset, sub(inputLength, 0x60)) {
                mstore(0, 0x3b99b53d) // SliceOutOfBounds()
                revert(0x1c, 0x04)
            }

            let permitBatchPointer := add(input.offset, permitBatchOffset)
            let detailsOffset := calldataload(permitBatchPointer)
            let permitBatchLength := sub(inputLength, permitBatchOffset)

            // The PermitDetails array length word must be contained in the PermitBatch slice.
            if gt(detailsOffset, sub(permitBatchLength, 0x20)) {
                mstore(0, 0x3b99b53d) // SliceOutOfBounds()
                revert(0x1c, 0x04)
            }

            let detailsLengthPointer := add(permitBatchPointer, detailsOffset)
            let detailsLength := calldataload(detailsLengthPointer)
            let detailsDataOffset := add(detailsOffset, 0x20)
            let remainingLength := sub(permitBatchLength, detailsDataOffset)

            // Each PermitDetails element occupies four words.
            if gt(detailsLength, div(remainingLength, 0x80)) {
                mstore(0, 0x3b99b53d) // SliceOutOfBounds()
                revert(0x1c, 0x04)
            }

            permitBatch := permitBatchPointer
        }
    }
}
