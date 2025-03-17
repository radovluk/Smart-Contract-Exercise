// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDCToken
 * @notice A simplified version of USDC Token
 *
 * ======== About the real USDC stablecoin ========
 * USD Coin (USDC) is a fully-collateralized US dollar stablecoin. 
 * It maintains a 1:1 peg to the US Dollar 1 USDC = $1 USD.
 *
 * Full Collateralization:
 *    - Each USDC token is backed by $1 USD held in regulated financial institutions
 *    - The reserves consist of cash and short-term US Treasury bonds
 *    - Monthly attestations are published by accounting firms verifying these reserves
 *
 *    - The real USDC includes functionality not present in this simplified version:
 *      a. Blacklisting: The ability to block specific addresses from using USDC
 *      b. Minting/Burning: Only authorized parties can mint or burn tokens (requires KYC)
 *      c. Upgradeability: The contract can be upgraded to address issues or add features
 *      d. Pausing: The ability to freeze all transfers in emergency situations
 *
 * Real USDC contract can be found at:
 * https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
 */
contract USDCToken is ERC20, Ownable {
    
    /// Emitted when new tokens are minted
    event TokensMinted(address indexed to, uint256 amount);
    
    /**
     * @dev Constructor initializes the token with name, symbol, and initial supply
     * @param initialSupply The initial amount of tokens to mint
     * 
     * Ownable(msg.sender) initializes the contract owner to be the deploying address,
     * granting them exclusive access to owner-restricted functions like mint()
     */
    constructor(uint256 initialSupply) ERC20("USD Coin", "USDC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
        
    /**
     * @dev Simplified mint function, restricted to owner
     * In real USDC, minting would:
     * - Require the caller to be an authorized minter
     * - Include compliance checks on the recipient
     * - Emit events for regulatory tracking
     * - Should only happen after USD is verifiably deposited with a USDC issuer
     * 
     * @param to The address receiving the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
}