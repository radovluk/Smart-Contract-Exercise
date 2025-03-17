// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "./CTUToken.sol";

/**
 * @title ReentrancyGuard
 * @notice A simple guard to deter reentrant calls. 
 *         It sets a boolean lock before function execution and resets it after.
 *         Though it helps, no guarantee this covers all possible attacks—be cautious.
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
    modifier noReentrant() {
        require(!locked, ReentrancyGuardError());
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
    CTUToken private ctuTokenContract;

    /// Tracks Ether balances for each investor address.
    mapping(address => uint) public balances;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    /// Emitted when an investor deposits Ether.
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

    /// Client attempts an action but lacks sufficient balance.
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
        require(msg.value > 0, DepositAmountMustBeGreaterThanZero());

        // Update the user's balance and emit a deposit event
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw all their Ether from the contract.
     *      Uses the noReentrant modifier to prevent reentrancy attacks.
     *      Emits a Withdraw event upon successful withdrawal.
     */
    function withdrawEther() public noReentrant {
        uint amount = balances[msg.sender];
        // Ensure the user has enough balance to withdraw
        require(
            amount >= 0,
            InsufficientBalance(balances[msg.sender], amount)
        );

        // Transfer the Ether to the user and reset their balance
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, TransferFailed());
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
        require(etherAmount >= 1 ether, InsufficientEtherForTokenPurchase());

        // Calculate the maximum number of tokens that can be bought
        uint tokenAmount = etherAmount / 1 ether;

        // Calculate the remaining Ether after buying tokens
        uint remainingEther = etherAmount % 1 ether;

        // Update the user's balance with the remaining Ether
        balances[msg.sender] = remainingEther;

        // Transfer the tokens to the user
        ctuTokenContract.transfer(msg.sender, tokenAmount);
        emit BuyTokens(msg.sender, tokenAmount);
    }

    /**
     * @dev Allows users to sell their CTU Tokens in exchange for Ether.
     *      Uses the noReentrant modifier to prevent reentrancy attacks.
     *      Emits a SellTokens event upon successful sale.
     * @param _amount The amount of CTU Tokens to sell.
     * @notice The user must have approved the CTUTokenBank to spend their tokens
     * before calling this function.
     * @notice The user must have enough tokens to sell.
     * @notice The user will receive Ether in exchange for their tokens in their bank balance.
     */
    function sellTokens(uint _amount) public noReentrant {
        // Ensure the user has enough tokens to sell
        require(
            ctuTokenContract.balanceOf(msg.sender) >= _amount,
            InsufficientBalance(ctuTokenContract.balanceOf(msg.sender), _amount)
        );
        // Calculate the Ether amount to add to the user's balance
        uint etherAmount = _amount * 1 ether;

        // Transfer the tokens from the user to the contract 
        // (fails if the user has not approved the contract)
        ctuTokenContract.transferFrom(msg.sender, address(this), _amount);

        // Update the user's balance with the Ether amount and emit a sell event
        balances[msg.sender] += etherAmount;
        emit SellTokens(msg.sender, _amount);
    }
}