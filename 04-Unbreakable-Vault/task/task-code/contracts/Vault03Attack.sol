// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IVault03 {
    function breachVault() external returns (bool);
}

contract Vault03Attack {
    IVault03 public vault;

    // Constructor to set the address of the vault contract
    constructor(address _vaultAddress) {
        vault = IVault03(_vaultAddress);
    }

    // Function to perform the attack
    function attack() external returns (bool) {
        // =========================
        // YOUR CODE GOES HERE
        // =========================
    }
}
