// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

  /** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault03 {
    // Address of the last person who solved the challenge
    address public lastSolver;

    /**
     * @notice Breach the vault by providing the correct password.
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault() public returns (bool) {
        // The caller of the function should not be same as the transaction origin.
        require(msg.sender != tx.origin,
            "Caller must not be the transaction origin"
        );
        lastSolver = tx.origin;
        return true;
    }
}
