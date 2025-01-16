// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title CTUGoldToken
 * @dev Custom ERC20 Token implementation leveraging OpenZeppelin's ERC20 contract.
 * see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 */
contract CTUGoldToken is ERC20 {
    /**
     * @dev Constructor that assigns the entire supply to the deployer.
     * @param initialSupply Initial token supply in smallest units 
     * (e.g., for 1 million tokens with 18 decimals, pass 10**24 10**6 * 10**18).
     */
    constructor(uint256 initialSupply) ERC20("CTU Gold Token", "CTUG") {
        _mint(msg.sender, initialSupply);
    }
}
