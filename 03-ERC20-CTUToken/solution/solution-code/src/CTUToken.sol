// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

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
    // ------------------------------------------------------------------------
    //                              Constants
    // ------------------------------------------------------------------------

    // The name of the token.
    string private constant TOKEN_NAME = "CTU Token";

    // The symbol of the token, usually a shorter version of the name.
    string private constant TOKEN_SYMBOL = "CTU";

    // The total supply of the token there will be.
    // 1,000,000 tokens with 18 decimal places
    uint256 private constant TOKEN_TOTAL_SUPPLY = 1_000_000 * 10 ** 18;

    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    // Mapping from account addresses to their current token balance
    mapping(address => uint256) private balances;

    // Mapping from account addresses to another account's allowances.
    // This allows an account to authorize another account to spend tokens on its behalf.
    mapping(address => mapping(address => uint256)) private allowances;

    // ------------------------------------------------------------------------
    //                              Events
    // ------------------------------------------------------------------------

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another account (`to`).
     * @param from Address from which tokens are moved.
     * @param to Address to which tokens are moved.
     * @param value The amount of tokens to be moved.
     *
     *  Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a spender for an owner is set by a call to `approve`.
     * `value` is the new allowance.
     *
     * @param owner Address of the owner who is setting the allowance.
     * @param spender Address of the spender who is being allowed to spend.
     * @param value The amount of tokens the spender is allowed to spend.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// Attempting to transfer to the zero address.
    error TransferToZeroAddress();
    /// Attempting to transfer from the zero address.
    error TransferFromZeroAddress();
    /// Account does not have enough balance. Requested:`requsted` Available:`available`
    error InsufficientBalance(uint256 requested, uint256 available);
    /// Attempting to approve the zero address as a spender.
    error ApproveToZeroAddress();
    /// Attempting to increase allowance for the zero address.
    error IncreaseAllowanceForZeroAddress();
    /// Attempting to decrease allowance for the zero address.
    error DecreaseAllowanceForZeroAddress();
    /// Attempting to decrease allowance=`requested` below the current value=`current`.
    error DecreasedAllowanceBelowZero(uint256 requested, uint256 current);
    /// Trying to transfer an amount=`requested` exceeding the current allowance=`allowance`.
    error TransferExceedsAllowance(uint256 requested, uint256 allowance);

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------

    /**
     * @dev Constructor that assigns the entire supply to the contract deployer.
     */
    constructor() {
        // Assign total supply to the contract deployer
        balances[msg.sender] = TOKEN_TOTAL_SUPPLY;

        // Emit Transfer event to show the inital token transfer
        emit Transfer(address(0), msg.sender, TOKEN_TOTAL_SUPPLY);
    }

    // ------------------------------------------------------------------------
    //                          ERC-20 Standard Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return TOKEN_NAME;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public pure returns (string memory) {
        return TOKEN_SYMBOL;
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
        return 18;
    }

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() public pure returns (uint256) {
        return TOKEN_TOTAL_SUPPLY;
    }

    /**
     * @dev Returns the value of tokens owned by `account`.
     * @param account The address from which the balance will be retrieved.
     */
    function balanceOf(address account) public view returns (uint256 balance) {
        return balances[account];
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
        // Check if the recipient is not the zero address
        require(to != address(0), TransferToZeroAddress());

        // Check if the sender has enough balance
        require(balances[msg.sender] >= value, InsufficientBalance(value, balances[msg.sender]));

        // Subtract the value from the sender's balance
        balances[msg.sender] -= value;

        // Add the value to the recipient's balance
        balances[to] += value;

        // Emit Transfer event
        emit Transfer(msg.sender, to, value);

        // Return true if the transfer is successful
        return true;
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
        // Check if the spender is not the zero address
        require(spender != address(0), ApproveToZeroAddress());

        // Set the allowance
        allowances[msg.sender][spender] = value;

        // Emit Approval event
        emit Approval(msg.sender, spender, value);

        // Return true if the approval is successful
        return true;
    }

    /**
     * @dev Increases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used to safely increment an allowance by `addedValue`.
     * This function mitigates the race condition by not setting a specific value directly.
     *
     * @param spender The address authorized to spend.
     * @param addedValue The amount by which the allowance is to be increased.
     * @return success A boolean indicating if the operation was successful.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool success) {
        // Check if the spender is not the zero address
        require(spender != address(0), IncreaseAllowanceForZeroAddress());

        // Increase the allowance
        allowances[msg.sender][spender] += addedValue;

        // Emit Approval event
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);

        // Return true if the operation is successful
        return true;
    }

    /**
     * @dev Decreases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used to safely decrement an allowance by `subtractedValue`.
     * This function mitigates the race condition by not setting a specific value directly.
     *
     * @param spender The address authorized to spend.
     * @param subtractedValue The amount by which the allowance is to be decreased.
     * @return success A boolean indicating if the operation was successful.
     *
     * Requirements:
     * - The current allowance must be at least `subtractedValue`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool success) {
        // Check if the spender is not the zero address
        require(spender != address(0), DecreaseAllowanceForZeroAddress());

        // Check if the current allowance is sufficient
        require(
            allowances[msg.sender][spender] >= subtractedValue,
            "Decreased allowance below zero"
        );

        // Decrease the allowance
        allowances[msg.sender][spender] -= subtractedValue;

        // Emit Approval event
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);

        // Return true if the operation is successful
        return true;
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
        return allowances[owner][spender];
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
        // Check if the sender is not the zero address
        require(from != address(0), TransferFromZeroAddress());

        // Check if the recipient is not the zero address
        require(to != address(0), TransferToZeroAddress());

        // Check if the sender has enough balance
        require(
            balances[from] >= value,
            InsufficientBalance(value, balances[from])
        );

        // Check if the caller has enough allowance
        require(
            allowances[from][msg.sender] >= value,
            TransferExceedsAllowance(value, allowances[from][msg.sender])
        );

        // Subtract the value from the sender's balance
        balances[from] -= value;

        // Add the value to the recipient's balance
        balances[to] += value;

        // Update allowance
        allowances[from][msg.sender] -= value;

        // Emit Transfer event
        emit Transfer(from, to, value);

        // Return true if the transfer is successful
        return true;
    }
}
