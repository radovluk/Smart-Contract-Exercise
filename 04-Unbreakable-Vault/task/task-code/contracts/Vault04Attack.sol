// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IVault04 {
    function breachVault(bytes32 _password) external returns (bool);
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
        // =========================
    }
}
