// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

  /** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault06 {
    // Address of the last person who solved the challenge
    address public lastSolver;

    // Private variable to store the password in text form
    string private password;

    constructor(string memory _password) {
        password = _password;
    }

    /**
     * @notice Breach the vault by providing the correct password.
     * @param _password The correct password required to complete the challenge.
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault(string memory _password) public returns (bool) {
        require(
            keccak256(abi.encodePacked(password)) ==
                keccak256(abi.encodePacked(_password)),
            "Incorrect password"
        );

        // Update the last solver to the current transaction origin
        lastSolver = tx.origin;
        return true;
    }
}
