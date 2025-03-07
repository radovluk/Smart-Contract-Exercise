// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault09 {
    // Address of the last person who solved the challenge
    address public lastSolver;
    
    // Internal token accounting
    mapping(address => uint256) public tokenBalances;
    
    // Approval mapping (owner => spender => amount)
    mapping(address => mapping(address => uint256)) public allowances;
    
    /**
     * @notice Constructor gives the deployer 1 000 000 token
     */
    constructor() {
        tokenBalances[msg.sender] = 1_000_000;
    }
    
    /**
     * @notice Approve another address to spend tokens on your behalf
     * @param spender Address authorized to spend tokens
     * @param amount Amount of tokens approved to spend
     */
    function approve(address spender, uint256 amount) external {
        allowances[msg.sender][spender] = amount;
    }
    
    /**
     * @notice Transfer tokens from one address to another
     * @param from Address to transfer tokens from
     * @param to Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function transferFrom(address from, address to, uint256 amount) external {
        // Check approval and balances
        require(tokenBalances[msg.sender] >= amount, "Not enough tokens");
        require(allowances[from][to] >= amount, "Not approved");

        // Update balances and allowances
        allowances[from][to] -= amount;
        tokenBalances[from] -= amount;
        tokenBalances[to] += amount;
    }
    
    /**
     * @notice Breach the vault by having more than 1,000,000 tokens
     * @return bool Returns true if the challenge was successfully completed
     */
    function breachVault() external returns (bool) {
        require(tokenBalances[msg.sender] >= 1_000_000, "You need at least 1,000,000 tokens");
        
        // Update the last solver to the current caller
        lastSolver = tx.origin;
        return true;
    }
}