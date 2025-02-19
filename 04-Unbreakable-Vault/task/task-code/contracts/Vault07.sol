// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/** VAULT CONTRACT - DO NOT CHANGE ANYTHING HERE */
contract Vault07 {
    // Address of the last person who solved the challenge
    address public lastSolver;

    // Bunch of variables important for the contract
    uint8 private small1 = 42;
    uint16 private small2 = 999;
    bool private isActive = true;
    uint256 private big1 = 1337;
    bytes32 private hashData = keccak256(abi.encode("You Shall Not Pass"));
    uint256 private big2 = 0xDEADBEEF;
    mapping(address => uint256) private d;

    // Private variable to store the password in text form
    string private password;

    constructor(string memory _password) {
        password = _password;
    }

    /**
     * @notice Breach the vault by providing the correct password.
     * @param _password The hash of the correct password required to complete the challenge.
     * @return bool Returns true if the challenge was successfully completed.
     */
    function breachVault(bytes32 _password) public returns (bool) {
        require(
            keccak256(abi.encodePacked(password)) == _password,
            "Incorrect password"
        );
        lastSolver = tx.origin;
        return true;
    }
}
