// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title Dummy contract that always reverts
/// @notice Used as a placeholder to ensure reverts on attempted calls to protocols unsupported on a given chain
contract UnsupportedProtocol { //@audit right here we want to UnsupportedProtcol
    error UnsupportedProtocolError(); //@audit we get the error 

    fallback() external { //@audit right here we want to fallback -> external from here 
        revert UnsupportedProtocolError();
    }
}
