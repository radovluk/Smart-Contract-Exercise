// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

  /** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault02 {
    // Address of the last person who solved the challenge
    address public lastSolver;

    /**
     * @notice Breach the vault by providing the correct password.
     * @param _password The correct password required to complete the challenge.
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault(uint256 _password) public returns (bool) {
        // Verify that the provided password matches the on-chain computed value.
        require(
            _password == uint256(keccak256(abi.encodePacked(msg.sender))),
            "Incorrect password"
        );
        lastSolver = tx.origin;
        return true;
    }
}
