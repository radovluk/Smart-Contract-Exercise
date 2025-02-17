// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

  /** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault05 {
    // Address of the last person who solved the challenge
    address public lastSolver;
    
    // Private variable to store the password
    bytes32 private password;
    
    // Block number when the password was locked in
    uint256 private lockInBlockNumber;

    /**
     * @notice Locks in the password and records the current block number.
     * @param _password The password to lock in.
     */
    function lockInPassword(bytes32 _password) public {
        password = _password;
        lockInBlockNumber = block.number;
    }

    /**
     * @notice You must call lockInPassword before you call this function.
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault() public returns (bool) {
        // Ensure that the current block number is greater than the block number when the password was locked in
        require(block.number > lockInBlockNumber, "Wait for the next block");

        // Verify that the provided password matches the on-chain computed value
        require(password == blockhash(lockInBlockNumber), "Incorrect password");

        // Update the last solver to the current transaction origin
        lastSolver = tx.origin;
        return true;
    }
}
