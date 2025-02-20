// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault05 {
    // Address of the last person who solved the challenge
    address public lastSolver;

    // Private variable to store the guess
    uint256 private guess;

    // Block number when the guess was locked in
    uint256 private lockInBlockNumber;

    /**
     * @notice Locks in the guess and records the current block number.
     * @param _guess The guessed random number to lock in.
     */
    function lockInGuess(uint256 _guess) public {
        guess = _guess;
        lockInBlockNumber = block.number;
    }

    /**
     * @notice You must call lockInGuess before you call this function.
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault() public returns (bool) {
        // Ensure that the current block number is greater than the block number when the guess was locked in
        require(block.number > lockInBlockNumber, "Wait for the next block");

        // Verify that the provided guess matches the on-chain computed value
        require(
            guess == uint256(blockhash(lockInBlockNumber)) % 100,
            "Incorrect guess"
        );

        // Update the last solver to the current transaction origin
        lastSolver = tx.origin;
        return true;
    }
}
