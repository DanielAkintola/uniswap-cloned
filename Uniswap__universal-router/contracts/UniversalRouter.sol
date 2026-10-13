// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

// Command implementations
import {Dispatcher} from './base/Dispatcher.sol';
import {RouteSigner} from './base/RouteSigner.sol';
import {RouterParameters} from './types/RouterParameters.sol';
import {PaymentsImmutables, PaymentsParameters} from './modules/PaymentsImmutables.sol';
import {UniswapImmutables, UniswapParameters} from './modules/uniswap/UniswapImmutables.sol';
import {V4SwapRouter} from './modules/uniswap/v4/V4SwapRouter.sol';
import {Commands} from './libraries/Commands.sol';
import {NestedUnlock} from './libraries/NestedUnlock.sol';
import {ResolvedAmount} from './libraries/ResolvedAmount.sol';
import {IUniversalRouter} from './interfaces/IUniversalRouter.sol';
import {MigratorImmutables, MigratorParameters} from './modules/MigratorImmutables.sol';
import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {ChainedActions} from './modules/ChainedActions.sol';

contract UniversalRouter is IUniversalRouter, ChainedActions, RouteSigner, Dispatcher { //@audit right here we have these guys inherited
    constructor(RouterParameters memory params) //@audit right here we have the constructor with the router parameters 
        UniswapImmutables(UniswapParameters(
                params.v2Factory, params.v3Factory, params.pairInitCodeHash, params.poolInitCodeHash
            ))
        V4SwapRouter(params.v4PoolManager, params.permissionsAdapterFactory) //@audit right here we also have the V4SwapRouter set 
        PaymentsImmutables(PaymentsParameters(params.permit2, params.weth9))
        MigratorImmutables(MigratorParameters(params.v3NFTPositionManager, params.v4PositionManager))
        ChainedActions(params.spokePool) //@audit right here we have the chainedActions too
        EIP712('UniversalRouter', '2')
    {}

    modifier checkDeadline(uint256 deadline) { //@audit right here we checked the block.timestamp > deadline 
        //@audit right here let's say the block.timestamp was like 2000 and the deadline is 3000
        if (block.timestamp > deadline) revert TransactionDeadlinePassed(); //@audit right here 
        _; //@audit right here we use this construct to continue execution
    }

    /// @notice To receive ETH from WETH
    receive() external payable { //@audit right here we checked if the msg.sender != weth and the msg.sender != poolmanaager
        if (msg.sender != address(WETH9) && msg.sender != address(poolManager)) revert InvalidEthSender();
        //@audit right here msg.sender != WETH9
        //@audit right here msg.sender != poolManager 
    }

    /// @inheritdoc IUniversalRouter
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        payable
        checkDeadline(deadline) //@audit right here we want to checkDeadline with those deadline shit too
    { 
        //@audit right here we execute it then from here 
        execute(commands, inputs); //@audit right here we have the commands too with the inputs and the deadline 
    }

    /// @inheritdoc IUniversalRouter
    function executeSigned(
        bytes calldata commands, 
        bytes[] calldata inputs,
        bytes32 intent, //@audit right here we have the intent 
        bytes32 data, //@audit right here we have the data 
        bool verifySender, //@audit right here we have the verifySender 
        bytes32 nonce, //@audit right here we have nonce 
        bytes calldata signature, //@audit right here we have the signature 
        uint256 deadline //@audit right here we have the deadline too 
    ) external payable checkDeadline(deadline) { //@audit right here we have the execute signed 
        // Set signature context and verify
        _setSignatureContext(commands, inputs, intent, data, verifySender, nonce, signature, deadline);
        // Execute commands
        execute(commands, inputs); //@audit right here we want to execute the comands with those inputs 
        // Clear signature context
        _resetSignatureContext(); //@audit right here we want to reset the signature context too
    }

    /// @inheritdoc IUniversalRouter
    function executeNested(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        payable
        checkDeadline(deadline)
    {
        _executeNested(commands, inputs); //@audit right here we want to execute the nested with these signatures 
    }

    /// @inheritdoc IUniversalRouter
    function executeNested(bytes calldata commands, bytes[] calldata inputs) external payable {
        _executeNested(commands, inputs); //@audit we want to transfer the execute Nested 
    } //@audit right here with those commands and inputs 

    function _executeNested(bytes calldata commands, bytes[] calldata inputs) private {
        NestedUnlock.set(true); //@audit right here we want to NestedUnlock.set(true)
        execute(commands, inputs); //@audit right here we allowed executing nested right here 
        NestedUnlock.set(false); 
    }

    /// @inheritdoc Dispatcher
    function execute(bytes calldata commands, bytes[] calldata inputs) public payable override isNotLocked {
        bool success; //@audit right here we have the success
        bytes memory output; //@audit right here we also have the outputs too
        uint256 numCommands = commands.length; //@audit right here we have the commands.length
        if (inputs.length != numCommands) revert LengthMismatch();  //@audit right here if the input's length is not the same as the command we revert the fuck away
        // loop through all given commands, execute them and pass along outputs as defined
        
        for (uint256 commandIndex = 0; commandIndex < numCommands; commandIndex++) { 
            //@audit right here we have the commandIndex = 0 and the commandIndex < numCommands and the commandIndex ++
            bytes1 command = commands[commandIndex]; 
            bytes calldata input = inputs[commandIndex]; 

            (success, output) = dispatch(command, input); 

            //@audit right here if it is not successful and success is required
            if (!success && successRequired(command)) { //@audit right here if it is not successful and success is required for the application
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            } //@note for a system that should require success if it doesn;t then we have an issue
        }

        // Clear the resolved-amount register on top-level exit so a value written by a RESOLVE command
        // never leaks into a later execute in the same transaction. Sub-plans reenter with
        // msg.sender == address(this) and intentionally keep the register live for the rest of the plan.
        //@audit right here if there is msg.sender and it is not equals to the address(this)
        if (msg.sender != address(this)) ResolvedAmount.reset(); //@audit right here we checked if the msg.sender != address(this) then we ResolvedAmount.reset()
    } //@audit right here if the msg.sebder != address(this) then we resolvedAmount.reset()

    /// @inheritdoc IUniversalRouter
    function signedRouteContext() external view returns (address signer, bytes32 intent, bytes32 data) {
        return _signedRouteContext();
    }

    function successRequired(bytes1 command) internal pure returns (bool) {
        //@audit right here if the commands.flag_allow_revert == 0 then we leave it alright there 
        //@audit if it doesn't allow revert then we leave 
        return command & Commands.FLAG_ALLOW_REVERT == 0;  //@audit right here we have this flag set from here 
        //@audit right here if the command & FLAG_ALLOW_REVERT == 0
        //@audit right here we continued from there 
    }

    // command is always a flag lol a number lol
}
