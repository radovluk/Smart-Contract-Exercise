// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FlashLoanProvider
 * @notice An EIP-3156 compliant flash loan provider for educational purposes
 *  For more information about EIP-3165 see https://eips.ethereum.org/EIPS/eip-3156
 *         - Provides standard-compliant flash loans for both ETH and USDC
 *         - Charges a fixed 0.01% fee on all flash loans (1 basis point)
 *         - All collected fees are retained in the contract, increasing the pool size
 *         - Supports ETH (address(0)) and USDC token as loan currencies
 *         - ETH loans are handled directly while USDC loans use ERC20 transfers
 */
contract FlashLoanProvider is IERC3156FlashLender {
    using SafeERC20 for IERC20;

    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    // The value that must be returned by borrowers to confirm a successful flash loan
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    // Fee in basis points (1/10000), fixed at 1 = 0.01% fee
    uint256 public constant FEE_BASIS_POINTS = 1;

    // USDC token contract
    IERC20 public immutable usdcToken;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    /// Emitted when a flash loan is initiated
    event FlashLoanInitiated(
        address indexed borrower,
        address token,
        uint256 amount
    );

    /// Emitted when a flash loan is successfully repaid
    event FlashLoanRepaid(
        address indexed borrower,
        address token,
        uint256 amount,
        uint256 fee
    );

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// Attempted to borrow an unsupported token (only ETH and USDC are supported)
    error UnsupportedToken();

    /// Not enough liquidity in the pool to fulfill the loan request
    error InsufficientLiquidity();

    /// ETH transfer to borrower failed
    error TransferToBorrowerFailed();

    /// Callback returned invalid value
    error InvalidCallbackReturn();

    /// Loan was not repaid with the required fee
    error LoanRepaymentFailed();

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------

    /**
     * @dev Initializes the flash loan provider with USDC token address
     * @param _usdcToken The address of the custom USDC token contract
     */
    constructor(address _usdcToken) payable {
        usdcToken = IERC20(_usdcToken);
    }

    // ------------------------------------------------------------------------
    //                          External Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Returns the maximum flash loan amount available
     * @param token The loan currency (address(0) for ETH, USDC token address for USDC)
     * @return The amount available for flash loans
     */
    function maxFlashLoan(
        address token
    ) external view override returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else if (token == address(usdcToken)) {
            return usdcToken.balanceOf(address(this));
        } else {
            return 0; // Only ETH and USDC are supported
        }
    }

    /**
     * @dev Calculates the fee for a given loan amount
     * @param token The loan currency (address(0) for ETH, USDC token address for USDC)
     * @param amount The amount of the loan
     * @return The fee amount (0.01% of the borrowed amount)
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view override returns (uint256) {
        if (token != address(0) && token != address(usdcToken)) {
            revert UnsupportedToken();
        }
        return (amount * FEE_BASIS_POINTS) / 10000;
    }

    /**
     * @dev Executes a flash loan for either ETH or USDC
     * @param receiver The contract receiving the loan
     * @param token The loan currency (address(0) for ETH, USDC token address for USDC)
     * @param amount The amount of the loan
     * @param data Arbitrary data to pass to the receiver
     * @return true if the flash loan was successful
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        // Validate token is supported
        if (token != address(0) && token != address(usdcToken)) {
            revert UnsupportedToken();
        }

        // Check if we have enough liquidity (either ETH or USDC)
        if (token == address(0)) {
            if (amount > address(this).balance) {
                revert InsufficientLiquidity();
            }
        } else {
            if (amount > usdcToken.balanceOf(address(this))) {
                revert InsufficientLiquidity();
            }
        }

        // Calculate the fee (0.01% of the borrowed amount)
        uint256 feeAmount = (amount * FEE_BASIS_POINTS) / 10000;

        // Store initial balance for validation after loan
        uint256 initialBalance;
        if (token == address(0)) {
            initialBalance = address(this).balance;
        } else {
            initialBalance = usdcToken.balanceOf(address(this));
        }

        // Emit loan initiation event
        emit FlashLoanInitiated(address(receiver), token, amount);

        // Transfer the requested asset to the borrower
        if (token == address(0)) {
            // ETH loan
            (bool success, ) = address(receiver).call{value: amount}("");
            if (!success) revert TransferToBorrowerFailed();
        } else {
            // USDC loan
            usdcToken.safeTransfer(address(receiver), amount);
        }

        // Execute the onFlashLoan callback on the borrower contract
        // This transfers control to the borrower's code, allowing them to use the borrowed funds
        bytes32 callbackResult = receiver.onFlashLoan(
            msg.sender,
            token,
            amount,
            feeAmount,
            data
        );

        // Verify callback return value
        if (callbackResult != CALLBACK_SUCCESS) {
            revert InvalidCallbackReturn();
        }

        // Verify repayment (balance should be initial balance + fee)
        uint256 finalBalance;
        if (token == address(0)) {
            finalBalance = address(this).balance;
        } else {
            finalBalance = usdcToken.balanceOf(address(this));
        }

        if (finalBalance < initialBalance + feeAmount) {
            revert LoanRepaymentFailed();
        }

        // Emit loan repayment event
        emit FlashLoanRepaid(address(receiver), token, amount, feeAmount);

        return true;
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {
        // Allow receiving ETH (for loan repayments and deposits)
    }
}
