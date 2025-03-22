// SPDX-License-Identifier: MIT
pragma solidity =0.8.28; // Specify the Solidity compiler version

/**
 * @title Greeter
 * @dev A simple smart contract that stores a greeting message.
 */
contract Greeter {
    string private greeting; // State variable to store the greeting message

    /**
     * @dev Constructor that sets the initial greeting message upon deployment.
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
