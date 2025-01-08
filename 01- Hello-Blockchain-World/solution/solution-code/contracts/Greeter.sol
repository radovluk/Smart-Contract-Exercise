// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Greeter
 * @dev A simple smart contract that stores a greeting message.
 */
contract Greeter {
    // State variable to store the greeting message
    string private greeting;

    /**
     * @dev Constructor that initializes the contract with a greeting.
     * @param _greeting The greeting message to be stored.
     */
    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    /**
     * @dev Function to retrieve the greeting message.
     * @return The current greeting stored in the contract.
     */
    function greet() public view returns (string memory) {
        return greeting;
    }
}
