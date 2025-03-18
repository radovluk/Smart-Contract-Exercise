// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

/**
 * @title PiggyBank
 * @dev A simple contract that allows deposits from anyone but only the owner can withdraw
 */
contract PiggyBank {
    address public immutable owner;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    
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
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= address(this).balance, "Not enough funds");
        totalWithdrawals += amount;
        payable(owner).transfer(amount);
    }
}