// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CTUToken
 * @dev A custom implementation of an ERC-20 Token.
 *
 * Features:
 * - Standard ERC-20 functions such as decimals, totalSupply, balanceOf,
 *   transfer, transferFrom, approve, and allowance.
 * - Events {Transfer} and {Approval} to track token movements and allowances.
 *
 * Note: This contract is intended for learning and experimentation. It is
 * not suitable for production use.
 *
 * For production, consider using the OpenZeppelin ERC-20 implementation:
 * https://docs.openzeppelin.com/contracts/4.x/erc20
 */
contract CTUToken {
    // TODO: Set the name of the token to "CTU Token"
    string private nameToken = "";

    // The symbol of the token, usually a shorter version of the name.
    string private symbolToken = "CTU";

    // TODO: Set the total supply of the token to 1,000,000 tokens.
    // The total supply should be 1,000,000 tokens with 18 decimal places.
    // This means the total supply should be represented as 1,000,000 * 10^18.
    uint256 private totalSupplyToken = 42;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another account (`to`).
     * @param from Address from which tokens are moved.
     * @param to Address to which tokens are moved.
     * @param value The amount of tokens to be moved.
     *
     *  Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // TODO: Implement the Approval event to track allowances.
    //
    // @dev Emitted when the allowance of a spender for an owner is set by a call to `approve`.
    // `value` is the new allowance.
    //
    // @param owner Address of the owner who is setting the allowance.
    // @param spender Address of the spender who is being allowed to spend.
    // @param value The amount of tokens the spender is allowed to spend.

    // Mapping from account addresses to their current token balance
    mapping(address => uint256) private balances;

    // Mapping from account addresses to another account's allowances.
    // This allows an account to authorize another account to spend tokens on its behalf.
    mapping(address => mapping(address => uint256)) private allowances;

    /**
     * @dev Constructor that assigns the entire supply to the contract deployer.
     */
    constructor() {
        // TODO: Assign total supply to the contract deployer
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        // TODO: Return the name of the token
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        // TODO: Return the symbol of the token
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `420` tokens should
     * be displayed to a user as `4.2` (`42 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for display purposes: it in
     * no way affects any of the arithmetic of the contract.
     */
    function decimals() public pure returns (uint8) {
        // TODO: uncomment the line below
        // return 18;
    }

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupplyToken;
    }

    /**
     * @dev Returns the value of tokens owned by `account`.
     * @param account The address from which the balance will be retrieved.
     */
    function balanceOf(address account) public view returns (uint256 balance) {
        // TODO: Return the balance of the account
    }

    /**
     * @dev Transfers value amount of tokens to address to.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return success A boolean indicating if the operation was successful.
     * @dev Emits a {Transfer} event.
     *
     * Requirements:
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public returns (bool success) {
        // TODO: Check if the recipient is not the zero address
        // TODO: Check if the sender has enough balance
        // TODO: Subtract the value from the sender's balance
        // TODO: Add the value to the recipient's balance
        // TODO: Emit Transfer event
        // TODO: Return true if the transfer is successful
    }

    /**
     * @dev Allows spender to withdraw from your account multiple times, up to the value amount.
     * @param spender The address authorized to spend.
     * @param value The maximum amount they can spend.
     * @return success A boolean indicating if the operation was successful.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 value
    ) public returns (bool success) {
        // TODO: Check if the spender is not the zero address
        // TODO: Set the allowance
        // TODO: Emit Approval event
        // TODO: Return true if the approval is successful
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256 remaining) {
        // TODO: Return the allowance of spender on owner's tokens
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return success A boolean indicating if the operation was successful.
     *
     * Requirements:
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     * - Transfer amount must be greater or equal than zero
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success) {
        // TODO: Check if the sender is not the zero address
        // TODO: Check if the recipient is not the zero address
        // TODO: Check if the sender has enough balance
        // TODO: Check if the caller has enough allowance
        // TODO: Subtract the value from the sender's balance
        // TODO: Add the value to the recipient's balance
        // TODO: Update allowance
        // TODO: Emit Transfer event
        // TODO: Return true if the transfer is successful
    }
}
