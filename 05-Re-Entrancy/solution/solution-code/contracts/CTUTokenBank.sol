// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "./CTUToken.sol";

/**
 * @title ReentrancyGuard
 * @notice A simple guard to deter reentrant calls.
 *         It sets a boolean lock before function execution and resets it after.
 */
abstract contract ReentrancyGuard {
    /// Indicates whether a function is currently locked from reentry.
    bool internal locked;

    /// Function is reentered illegally.
    error ReentrancyGuardError();

    /**
     * @dev Prevents reentrant calls to a function.
     *      Reverts if the lock is already engaged.
     */
    modifier nonReentrant() {
        if (locked) revert ReentrancyGuardError();
        locked = true;
        _;
        locked = false;
    }
}

/**
 * @title CTUTokenBank
 * @notice This contract allows users to deposit Ether, withdraw Ether, buy CTU Tokens deposited using Ether,
 * and sell CTU Tokens in exchange for Ether.
 * - It integrates with the CTUToken contract to facilitate token transactions.
 * - The contract uses a ReentrancyGuard to prevent reentrancy attacks on critical functions.
 * - Users can deposit Ether into the contract, which is tracked in a balances mapping.
 * - They can withdraw their Ether, buy CTU Tokens with their deposited Ether, or sell their CTU Tokens for Ether.
 * - The price of 1 CTU Token is fixed to 1 Ether.
 */
contract CTUTokenBank is ReentrancyGuard {
    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    /// Reference to the CTUToken contract.
    CTUToken private immutable ctuTokenContract;

    /// Tracks Ether balances for each investor address.
    mapping(address => uint) public balances;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    /// Emitted when an investor deposits Ether.
    /// @param investor The address of the investor who made the deposit.
    /// @param amount The amount of Ether deposited in wei.
    event Deposit(address indexed investor, uint amount);

    /// Emitted when an investor withdraws Ether.
    event Withdraw(address indexed investor, uint amount);

    /// Emitted when an investor buys CTU Tokens.
    event BuyTokens(address indexed investor, uint amount);

    /// Emitted when an investor sells CTU Tokens.
    event SellTokens(address indexed investor, uint amount);

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// Insufficient balance for transfer. Needed `amount` but only
    /// `balance` available.
    /// @param balance balance available.
    /// @param amount requested amount to transfer.
    error InsufficientBalance(uint balance, uint amount);

    /// Deposit is made with zero Ether.
    error DepositAmountMustBeGreaterThanZero();

    /// Transfer of Ether fails.
    error TransferFailed();

    /// Not enough Ether to buy at least 1 token.
    error InsufficientEtherForTokenPurchase();

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------

    /**
     * @dev Links the CTUTokenBank to a deployed CTUToken contract.
     * @param _ctuTokenAddress The address of the CTUToken contract.
     */
    constructor(address _ctuTokenAddress) {
        ctuTokenContract = CTUToken(_ctuTokenAddress);
    }

    // ------------------------------------------------------------------------
    //                          Contract Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to deposit Ether into the contract.
     *      Emits a Deposit event upon successful deposit.
     * @notice Only the deposited Ether will be used to buy CTU Tokens.
     */
    function depositEther() public payable {
        // Ensure the deposit amount is greater than zero
        if (msg.value <= 0) revert DepositAmountMustBeGreaterThanZero();

        // Update the user's balance and emit a deposit event
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw all their Ether from the contract.
     *      Uses the nonReentrant modifier to prevent reentrancy attacks.
     *      Emits a Withdraw event upon successful withdrawal.
     */
    function withdrawEther() public nonReentrant {
        uint amount = balances[msg.sender];
        // Ensure the user has enough balance to withdraw
        if (amount <= 0)
            revert InsufficientBalance(balances[msg.sender], amount);

        // Transfer the Ether to the user and reset their balance
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
        balances[msg.sender] = 0;
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Allows users to buy CTU Tokens using their deposited Ether.
     *      Emits a BuyTokens event upon successful purchase.
     * - The price of 1 CTU Token is fixed to 1 Ether.
     */
    function buyTokens() public {
        // Ensure the user has enough Ether to buy at least 1 token
        uint etherAmount = balances[msg.sender];
        if (etherAmount < 1 ether) revert InsufficientEtherForTokenPurchase();

        // Calculate the maximum number of tokens that can be bought
        uint tokenAmount = etherAmount / 1 ether;

        // Calculate the remaining Ether after buying tokens
        uint remainingEther = etherAmount % 1 ether;

        // Update the user's balance with the remaining Ether
        balances[msg.sender] = remainingEther;

        // Emit a buy event
        emit BuyTokens(msg.sender, tokenAmount);

        // Transfer the tokens to the user
        bool success = ctuTokenContract.transfer(msg.sender, tokenAmount);
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Allows users to sell their CTU Tokens in exchange for Ether.
     *      Uses the nonReentrant modifier to prevent reentrancy attacks.
     *      Emits a SellTokens event upon successful sale.
     * @param amount The amount of CTU Tokens to sell.
     * @notice The user must have approved the CTUTokenBank to spend their tokens
     * before calling this function.
     * @notice The user must have enough tokens to sell.
     * @notice The user will receive Ether in exchange for their tokens in their bank balance.
     */
    function sellTokens(uint amount) public nonReentrant {
        // Ensure the user has enough tokens to sell
        if (ctuTokenContract.balanceOf(msg.sender) < amount)
            revert InsufficientBalance(
                ctuTokenContract.balanceOf(msg.sender),
                amount
            );

        // Calculate the Ether amount to add to the user's balance
        uint etherAmount = amount * 1 ether;

        // Emit a sell event
        emit SellTokens(msg.sender, amount);

        // Transfer the tokens from the user to the contract
        // (fails if the user has not approved the contract)
        bool success = ctuTokenContract.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) revert TransferFailed();

        // Update the user's balance with the Ether amount and emit a sell event
        balances[msg.sender] += etherAmount;
    }
}
