// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {EIP712} from '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {ROUTE_SIGNER_SLOT, ROUTE_INTENT_SLOT, ROUTE_DATA_SLOT} from '../libraries/TransientSlots.sol';

/// @title RouteSigner
/// @notice Contract for managing signed execution context using transient storage
abstract contract RouteSigner is EIP712 {
    /// @notice EIP712 typehash for signed execution
    bytes32 internal constant EXECUTE_SIGNED_TYPEHASH = keccak256(
        'ExecuteSigned(bytes commands,bytes[] inputs,bytes32 intent,bytes32 data,address sender,bytes32 nonce,uint256 deadline)'
    );

    /// @notice Mapping of used nonces for replay protection
    /// @dev Unordered nonces allow parallel execution of signed routes
    mapping(address user => mapping(bytes32 nonce => bool used)) public noncesUsed;

    /// @notice Thrown when a nonce has already been used
    error NonceAlreadyUsed();

    /// @dev Stores the signature context (signer, intent, data) in transient storage
    function _setSignatureContext(
        bytes calldata commands, //@audit right here we have the commands too
        bytes[] calldata inputs, //@audit we have the inputs 
        bytes32 intent, //@audit right here we have the intent  
        bytes32 data, //@audit right here we have the data
        bool verifySender, //@audit right here we have the verifySender
        bytes32 nonce, //@audit right here we have the nonce 
        bytes calldata signature, //@audit right here we have the signature too
        uint256 deadline //@audit right here we have the deadline
    ) internal returns (address signer) {
        // Hash the inputs array per EIP712: hash each element, concatenate, then hash again
        uint256 inputsLength = inputs.length; //@audit right here we have the inputs.length
        
        //@audit right here we have the inputs.length
        //@audit right here we have the input hashes given the input's length 
        bytes32[] memory inputHashes = new bytes32[](inputsLength);  //@audit right here we have a input hashes 
        for (uint256 i = 0; i < inputsLength; ++i) { //@audit right here we have the inputs length 
            inputHashes[i] = keccak256(inputs[i]); 
            //@audit right here we hashed the inputs[i] with the keccak256 -> inputs[i]
            //@audit right here we set the inputHashes[i] at a particular index to it's hash at the hash of inputs[i]
            //@audit right here we hash each of those inputs 
        }


        //@audit right here we want to encodePacked the inputHashes
        bytes32 inputsHash = keccak256(abi.encodePacked(inputHashes)); //@audit right here we hash the bytes of encoded of it 

        // Determine sender for signature verification
        address sender = verifySender ? msg.sender : address(0); //@audit right here we have the verifySender if it is msg.sender else we got zero addresss from here 

        // Construct EIP712 hash
        bytes32 structHash = keccak256( //@audit right here we want to perform structhash
            abi.encode(EXECUTE_SIGNED_TYPEHASH, keccak256(commands), inputsHash, intent, data, sender, nonce, deadline)
        );
        //@audit right here we have the structHash
        //@audit right here we performed a struct hash action on these things 


        //@audit right here we have the hashTYpedDatav4 
        bytes32 digest = _hashTypedDataV4(structHash); //@audit right here too we performed a hashTypedDataV4 on the structHash

        // Recover signer
        signer = ECDSA.recover(digest, signature);

        // Check and mark nonce as used (skip if nonce == bytes32(type(uint256).max))
        if (nonce != bytes32(type(uint256).max)) { //@audit right here if the nonce is max then we can revert 
            if (noncesUsed[signer][nonce]) revert NonceAlreadyUsed(); //@audit right here we also set the noncesUsed[signer][nonce] revert NonceAlreadyUsed 
            noncesUsed[signer][nonce] = true; //@audit right here we set the noncesUsed[signer][nonce]
        }

        // Store signer, intent, and data in transient storage
        assembly ('memory-safe') { //@audit right here we tstored the ROUTE_SIGNER_SLOT with those signer
            tstore(ROUTE_SIGNER_SLOT, signer) //@audit we just got the signer and the intent and those data too
            tstore(ROUTE_INTENT_SLOT, intent) //@audit right here we performed the ROUTE_INTENT_SLOT with those intent 
            tstore(ROUTE_DATA_SLOT, data) //@audit right here also we performed the ROUTE_DATA_SLOT with those data 
        }
    }

    /// @dev Clears the signature context from transient storage
    function _resetSignatureContext() internal {
        assembly ('memory-safe') { //@audit right here we have the signer 
            tstore(ROUTE_SIGNER_SLOT, 0) 
            tstore(ROUTE_INTENT_SLOT, 0) //@audit right here we have the intent too
            tstore(ROUTE_DATA_SLOT, 0) //@audit right here we have the data 
        }
    }

    /// @dev Internal function to read signed route context from transient storage
    function _signedRouteContext() internal view returns (address signer, bytes32 intent, bytes32 data) {
        assembly ('memory-safe') { //@audit right here we loaded the signer, we loaded the intent and then we loaded the data 
            signer := tload(ROUTE_SIGNER_SLOT)
            intent := tload(ROUTE_INTENT_SLOT)
            data := tload(ROUTE_DATA_SLOT)
        }
    }
}
