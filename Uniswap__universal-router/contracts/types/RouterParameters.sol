// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

struct RouterParameters {
    // Payment parameters
    address permit2; //@audit right here we have the permit2 account
    address weth9; //@audit we also have a weth9 account 
    // Uniswap swapping parameters
    address v2Factory; //@audit right here we have the v2Factory
    address v3Factory; //@audit right here we also have the v3Factory
    bytes32 pairInitCodeHash; //@audit right here we have the pairInitCodeHash
    bytes32 poolInitCodeHash; //@audit right here also we have the poolInitCodeHash
    address v4PoolManager; //@audit right here we also have the v4PoolManager
    address permissionsAdapterFactory; //@audit right here also we have the permissionsAdapterFactory
    // Uniswap v3->v4 migration parameters
    address v3NFTPositionManager; //@audit right here also we have the v3NFTPositionManager
    address v4PositionManager; //@audit right here we have the v4PositionManager 
    // Across parameters
    address spokePool; //@audit right here we have the spokePool
}
