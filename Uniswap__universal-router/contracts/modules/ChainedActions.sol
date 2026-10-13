// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Payments} from './Payments.sol';
import {IV3SpokePool} from '../interfaces/external/IV3SpokePool.sol';
import {AcrossV4DepositV3Params} from '../interfaces/IUniversalRouter.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ActionConstants} from '@uniswap/v4-periphery/src/libraries/ActionConstants.sol';
import {ResolvedAmount} from '../libraries/ResolvedAmount.sol';

abstract contract ChainedActions is Payments {
    using SafeERC20 for IERC20;

    IV3SpokePool public immutable SPOKE_POOL;

    constructor(address spokePool) { //@audit right here we have the spokepool
        SPOKE_POOL = IV3SpokePool(spokePool); //@audit right here we set the spoke_pool right away from here 
    } //@audit we have set the spoke pool

    function _acrossV4DepositV3(bytes calldata input) internal {
        AcrossV4DepositV3Params memory params = abi.decode(input, (AcrossV4DepositV3Params)); //@audit right here we are assuming 
        //@audit the input will be of the encoded type of params

        uint256 inputAmount = ResolvedAmount.map(params.inputAmount); //@audit here we want to map the inputAmount and map it what do we need to do
        uint256 callValue = 0; //@audit callValue is declared 

        // Resolve sentinel value for inputAmount
        if (inputAmount == ActionConstants.CONTRACT_BALANCE) { //@audit use contract_balance 
            if (params.useNative) { //@audit right here we want to useNative 
                inputAmount = address(this).balance; //@audit right here then and there we update our 
            } else { //@audit right here we have the balanceOf the inputAmount too
                inputAmount = IERC20(params.inputToken).balanceOf(address(this)); //@audit right here too 
            }
        }

        if (params.useNative) {
            // Require ETH path to use WETH as inputToken per Across docs.
            // Router must currently hold ETH equal to inputAmount.
            callValue = inputAmount; //@audit right here we have the callValut to be the input amount 
        } else {
            // Approve SpokePool to pull ERC20 from router
            //@audit right here else we approved the spoke_pool to use that input amount 
            IERC20(params.inputToken).forceApprove(address(SPOKE_POOL), inputAmount); //@audit right here we approved the spoke_pool the input amount right here and there 
        }

        SPOKE_POOL.depositV3{value: callValue}( //@audit right here and there this is performed 
            params.depositor,
            params.recipient,
            params.inputToken, //@audit right here 
            params.outputToken, //@audit right here we have the 
            inputAmount,
            params.outputAmount,
            params.destinationChainId,
            params.exclusiveRelayer,
            params.quoteTimestamp,
            params.fillDeadline,
            params.exclusivityDeadline,
            params.message
        );
    }
}
