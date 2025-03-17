// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin's ERC20 implementation
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title CTUTokenOpenZeppelin
 * @dev A custom implementation of an ERC-20 Token using OpenZeppelin's library.
 *
 * Features:
 * - Inherits standard ERC-20 functionalities such as decimals, totalSupply, balanceOf,
 *   transfer, transferFrom, approve, and allowance from OpenZeppelin.
 *
 * Note:
 * - Using OpenZeppelin's implementation is always recommended for its security, reliability,
 *   and community trust. It reduces the risk of vulnerabilities and leverages well-tested code.
 *   Do not reinvent the wheel!
 */
contract CTUTokenOpenZeppelin is ERC20 {
    // Define the initial supply: 1,000,000 tokens with 18 decimal places
    uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

    /**
     * @dev Constructor that initializes the ERC-20 token with a name and symbol,
     * and mints the total supply to the deployer's address.
     */
    constructor() ERC20("CTU Token", "CTU") {
        // Mint the initial supply to the deployer of the contract
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
