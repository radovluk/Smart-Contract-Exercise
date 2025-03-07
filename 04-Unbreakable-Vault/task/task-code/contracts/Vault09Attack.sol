// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


interface IVault09 {
    function transferFrom(address from, address to, uint256 amount) external;
}

/**
 * @title Attack contract for Vault09
 */
contract Vault09Attack {
    // Reference to the vulnerable vault contract
    IVault09 public vault;

    /**
     * @param _vaultAddress The address of the vulnerable Vault09 contract
     */
    constructor(address _vaultAddress) {
        vault = IVault09(_vaultAddress);
    }
    
    /**
     * @notice Performs the attack by triggering an underflow in the vault contract
     */
    function attack() external {      
        // =========================
        // TODO: YOUR CODE GOES HERE
        // =========================
    }
}

