// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FlashLoanReceiver
 * @notice A minimal template for receiving flash loans via the ERC-3156 standard
 */
contract FlashLoanReceiver is IERC3156FlashBorrower {
    // The flash loan provider contract
    IERC3156FlashLender public immutable lender;
    
    // Required return value for the flash loan callback
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    
    // Contract owner address
    address public owner;
    
    // Custom errors
    error NotOwner();
    error UntrustedLender();
    error UnauthorizedInitiator();

    /**
     * @dev Constructor to initialize the flash loan receiver
     * @param _lender The address of the ERC-3156 flash loan provider
     */
    constructor(address _lender) {
        lender = IERC3156FlashLender(_lender);
        owner = msg.sender;
    }
    
    /**
     * @dev Modifier to restrict access to the owner
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    /**
     * @dev Executes a flash loan
     * @param token The address of the token to borrow (address(0) for ETH)
     * @param amount The amount to borrow
     * @param data Additional data to pass to the callback function
     */
    function executeFlashLoan(
        address token,
        uint256 amount,
        bytes calldata data
    ) external onlyOwner {
        // Calculate fee
        uint256 fee = lender.flashFee(token, amount);
        
        // Execute the flash loan
        lender.flashLoan(this, token, amount, data);
    }

    /**
     * @dev Flash loan callback function required by the ERC-3156 standard
     * @param initiator The address that initiated the flash loan
     * @param token The token that was borrowed
     * @param amount The amount that was borrowed
     * @param fee The fee that needs to be paid
     * @param data Additional data passed from the executeFlashLoan function
     * @return bytes32 value indicating successful execution
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        // Security checks
        if (msg.sender != address(lender)) revert UntrustedLender();
        if (initiator != address(this)) revert UnauthorizedInitiator();
        
        // TODO: Add your flash loan logic here
        // This is where you implement your custom logic using the borrowed funds
        
        // For example:
        // 1. Use the borrowed funds for your operation (arbitrage, liquidation, etc.)
        // 2. Ensure you have enough tokens to repay the loan plus fee
        
        // Approve lender to take the amount + fee back
        if (token != address(0)) { // If token is not ETH
            IERC20(token).transfer(address(lender), amount + fee);
        } else { // Transfer ETH back to the lender
            (bool success, ) = address(lender).call{value: amount + fee}("");
            require(success, "ETH transfer failed");
        }
        
        // Return success value
        return CALLBACK_SUCCESS;
    }
    
    /**
     * @dev Function to receive ETH
     */
    receive() external payable {}
}