// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

  /** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault04 {
    // Address of the last person who solved the challenge
    address public lastSolver;

    /**
     * @notice Breach the vault by providing the correct password.
     * @param _password The correct password required to complete the challenge.
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault(bytes32 _password) public returns (bool) {
        // Verify that the provided password matches the on-chain computed value.
        require(
            _password ==
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp
                    )
                ),
            "Incorrect password"
        );
        lastSolver = tx.origin;
        return true;
    }
}
