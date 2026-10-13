// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title For calculating a percentage of an amount, using bips
library BipsLibrary {
    uint256 internal constant BPS_DENOMINATOR = 10_000; //@audit right here the bips_denom is 1e4

    /// @notice emitted when an invalid percentage is provided
    error InvalidBips();

    /// @param amount The total amount to calculate a percentage of
    /// @param bips The percentage to calculate, in bips
    function calculatePortion(uint256 amount, uint256 bips) internal pure returns (uint256) {
        if (bips > BPS_DENOMINATOR) revert InvalidBips(); //@audit right here we checked if the bips > bps_denom
        return (amount * bips) / BPS_DENOMINATOR; //@audit right here we calculated the amount * bips / bps_denom
    }
}
