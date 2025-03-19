// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

/**
 * @title PiggyBank
 * @dev A simple contract that allows deposits from anyone but only the owner can withdraw
 */
contract PiggyBank {
    // Contract owner who can withdraw funds
    address public immutable owner;
    // Tracks total ETH deposited
    uint256 public totalDeposits;
    // Tracks total ETH withdrawn
    uint256 public totalWithdrawals;
    
    // Custom errors
    error NotOwner();
    error InsufficientFunds();
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Allows anyone to deposit ETH
     */
    function deposit() public payable {
        totalDeposits += msg.value;
    }
    
    /**
     * @dev Allows only the owner to withdraw
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 amount) public {
        if (msg.sender != owner) revert NotOwner();
        if (amount > address(this).balance) revert InsufficientFunds();
        
        totalWithdrawals += amount;
        payable(owner).transfer(amount);
    }
}