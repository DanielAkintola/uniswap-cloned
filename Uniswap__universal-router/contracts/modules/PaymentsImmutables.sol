// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IWETH9} from '@uniswap/v4-periphery/src/interfaces/external/IWETH9.sol';
import {IPermit2} from 'permit2/src/interfaces/IPermit2.sol';

struct PaymentsParameters {
    address permit2; //@audit right here we have the permit2
    address weth9; //@audit right here we also have the weth9 too
}

contract PaymentsImmutables {
    /// @notice WETH9 address
    IWETH9 internal immutable WETH9; //@audit right here we have immutables 

    /// @notice Permit2 address
    IPermit2 internal immutable PERMIT2; //@audit right here we also have the permit2 set here too

    constructor(PaymentsParameters memory params) { //@audit right here we have the params guy here 
        WETH9 = IWETH9(params.weth9);//@audit right here we have the weth9 set  
        PERMIT2 = IPermit2(params.permit2); //@audit right here also we have the permit2 set 
    }  //@audit right here we store these values 
}
