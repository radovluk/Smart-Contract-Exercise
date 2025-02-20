// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault04 {
    // Address of the last person who solved the challenge
    address public lastSolver;

    /**
     * @notice Breach the vault by providing the correct guess.
     * @param guess Guess of the random number
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault(uint256 guess) public returns (bool) {
        // Verify that the provided guess matches the on-chain computed value.
        require(
            guess ==
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - 1),
                            block.timestamp
                        )
                    )
                ) % 100,
            "Incorrect guess"
        );
        lastSolver = tx.origin;
        return true;
    }
}
