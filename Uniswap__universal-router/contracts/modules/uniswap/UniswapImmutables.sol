// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

struct UniswapParameters {
    address v2Factory;
    address v3Factory;
    bytes32 pairInitCodeHash;
    bytes32 poolInitCodeHash;
}

contract UniswapImmutables {
    /// @notice The address of UniswapV2Factory
    address internal immutable UNISWAP_V2_FACTORY;

    /// @notice The UniswapV2Pair initcodehash
    bytes32 internal immutable UNISWAP_V2_PAIR_INIT_CODE_HASH;

    /// @notice The address of UniswapV3Factory
    address internal immutable UNISWAP_V3_FACTORY;

    /// @notice The UniswapV3Pool initcodehash
    bytes32 internal immutable UNISWAP_V3_POOL_INIT_CODE_HASH;

    constructor(UniswapParameters memory params) { //@audit right here we have the 
        UNISWAP_V2_FACTORY = params.v2Factory; //@audit right here we had the uniswapv2 factory
        UNISWAP_V2_PAIR_INIT_CODE_HASH = params.pairInitCodeHash; //@audit right here we have the pait init code hash too
        UNISWAP_V3_FACTORY = params.v3Factory; //@audit right here we also have the v3Factory too
        UNISWAP_V3_POOL_INIT_CODE_HASH = params.poolInitCodeHash; //@audit right here we have the pool init code hash too
    }
}
