// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault08 {
    // Address of the last person who solved the challenge
    address public lastSolver;
    
    // Internal token accounting
    mapping(address => uint256) public tokenBalances;

    // Price of each token
    uint256 public constant TOKEN_PRICE = 1 ether;
    
    /**
     * @notice Buy tokens by sending ether
     * @param numTokens Number of tokens to purchase
     */
    function buyTokens(uint256 numTokens) public payable {
        require(msg.value == numTokens * TOKEN_PRICE, "Incorrect payment amount");
        tokenBalances[msg.sender] += numTokens;
    }
    
    /**
     * @notice Breach the vault by draining its ether balance
     * @return bool Returns true if the challenge was successfully completed
     */
    function breachVault() public returns (bool) {
        require(tokenBalances[msg.sender] >= 1_000_000, "You don't have enough tokens");
        
        // Update the last solver to the current transaction origin
        lastSolver = tx.origin;
        return true;
    }
    
    // Allow the contract to receive ether
    receive() external payable {}
}