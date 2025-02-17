// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Vault01 {
    bool public unlocked = false;
    uint256 private password;

    modifier isUnlocked() {
        require(unlocked, "Vault is not unlocked");
        _;
    }

    constructor() {
        password = uint256(keccak256("password"));
    }   

    // Unlock the vault with the correct password
    function unlock(uint256 _password) public {
        if (_password == password) {
            unlocked = true;
        }
    }

    /**
     * @notice Steal the money after unlocking the vault.
     * @dev This function can only be called when the vault is unlocked.
     * It locks the vault after stealing the money to ensure it is locked for future students.
     * @return bool Returns true if you have successfully stolen the money.
     */
    function steal() public isUnlocked returns (bool) {
        unlocked = false;
        return true; //TODO think about the revert mechanism
    }
}
