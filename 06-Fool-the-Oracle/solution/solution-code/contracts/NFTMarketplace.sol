// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ISimpleDEX
 * Interface for SimpleDEX
 */
interface ISimpleDEX {
    function getCurrentUsdcToEthPrice() external view returns (uint);
}

/**
 * @title IFELStudentNFT
 * Interface for FELStudentNFT
 */
interface IFELStudentNFT {
    function getTraits(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @title FELStudentNFTMarketplace
 * @notice A marketplace for trading CTU FEL Student NFTs
 *         - Uses SimpleDEX exchange as a price oracle
 *         - Sells FEL student NFTs with different traits
 *         - Each NFT has an individual price set by the owner in USD
 *         - Calculates the ETH price based on current USD/ETH exchange rate
 *         - USDC token is used as a reference for USD equivalent, 1 USD = 1 USDC
 *         - Allows users to purchase NFTs for the calculated ETH price
 *         - Provides listing functionality to view all available NFTs with prices
 */
contract FELStudentNFTMarketplace is ReentrancyGuard, Ownable {
    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    // The SimpleDEX exchange used as a price oracle
    ISimpleDEX public immutable dexExchange;

    // The FEL Student NFT contract that this marketplace trades
    IFELStudentNFT public immutable nftContract;

    // The USDC token contract (used as USD equivalent)
    IERC20 public immutable usdcToken;

    // Maps token IDs to their prices in USD (with 18 decimals)
    mapping(uint256 => uint256) public nftPrices;

    // Default price for NFTs in USD (1000 USD with 18 decimals)
    uint256 public defaultPrice = 1000e18;

    // Tracking for listed NFTs
    mapping(uint256 => bool) private listedNFTs;
    uint256[] private listedTokenIds;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    /// Emitted when an NFT is purchased from the marketplace
    event NFTPurchased(
        address indexed buyer,
        uint256 tokenId,
        uint256 priceInEth
    );

    /// Emitted when an NFT is received by the marketplace
    event NFTReceived(address indexed sender, uint256 tokenId);

    /// Emitted when an NFT price is set
    event NFTPriceSet(uint256 indexed tokenId, uint256 priceInUSD);

    /// Emitted when the default price is updated
    event DefaultPriceUpdated(uint256 oldPrice, uint256 newPrice);

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// NFT is not owned by the marketplace
    error NotOwnedByMarketplace();

    /// Insufficient ETH sent to purchase the NFT
    error InsufficientETHSent();

    /// ETH refund failed
    error ETHRefundFailed();

    /// Invalid price (zero price not allowed)
    error InvalidPrice();

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------

    /**
     * @dev Initializes the marketplace with necessary contract addresses and sets the owner
     * @param _dexExchange Address of the SimpleDEX exchange to use as price oracle
     * @param _nftContract Address of the FEL Student NFT contract traded in this marketplace
     * @param _usdcToken Address of the USDC token contract (used as USD equivalent)
     */
    constructor(
        address _dexExchange,
        address _nftContract,
        address _usdcToken
    ) Ownable(msg.sender) {
        dexExchange = ISimpleDEX(_dexExchange);
        nftContract = IFELStudentNFT(_nftContract);
        usdcToken = IERC20(_usdcToken);
    }

    // ------------------------------------------------------------------------
    //                          External Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to buy a FEL Student NFT from the marketplace
     *      The price is calculated based on the current USD/ETH exchange rate
     * @param tokenId The ID of the NFT to purchase
     */
    function buyNFT(uint256 tokenId) external payable nonReentrant {
        // Verify the NFT is owned by the marketplace
        if (nftContract.ownerOf(tokenId) != address(this)) {
            revert NotOwnedByMarketplace();
        }

        // Get the price in USD (use individual price if set, otherwise use default)
        uint256 priceInUSD = getPriceForNFT(tokenId);

        // Get the current ETH price in USD from SimpleDEX
        uint usdPerEth = dexExchange.getCurrentUsdcToEthPrice();

        // Calculate how much ETH the buyer needs to pay
        // priceInUSD / usdPerEth = priceInEth
        uint priceInEth = (priceInUSD * 1e18) / usdPerEth;

        // Verify sufficient ETH was sent
        if (msg.value < priceInEth) {
            revert InsufficientETHSent();
        }

        // Store excess ETH amount before state changes
        uint256 excessEth = msg.value > priceInEth ? msg.value - priceInEth : 0;

        // Remove the price mapping for the sold NFT
        delete nftPrices[tokenId];

        // Remove from listed NFTs tracking
        if (listedNFTs[tokenId]) {
            listedNFTs[tokenId] = false;
            _removeTokenFromListing(tokenId);
        }

        // Transfer the NFT to the buyer
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        // Refund excess ETH if any
        if (excessEth > 0) {
            // Use a more secure refund pattern
            (bool success, ) = msg.sender.call{value: excessEth}("");
            if (!success) {
                revert ETHRefundFailed();
            }
        }

        emit NFTPurchased(msg.sender, tokenId, priceInEth);
    }

    /**
     * @dev Allows the marketplace to receive NFTs for sale
     * @param tokenId The ID of the NFT to receive
     */
    function receiveNFT(uint256 tokenId) external nonReentrant {
        // Add to listed NFTs tracking
        bool wasListed = listedNFTs[tokenId];
        listedNFTs[tokenId] = true;

        if (!wasListed) {
            listedTokenIds.push(tokenId);
        }

        // External calls come last
        nftContract.transferFrom(msg.sender, address(this), tokenId);

        emit NFTReceived(msg.sender, tokenId);
    }

    /**
     * @dev Returns the current price of a specific NFT in ETH
     * @param tokenId The ID of the NFT to query
     * @return The price in ETH with 18 decimals precision
     */
    function getCurrentPriceForNFT(
        uint256 tokenId
    ) external view returns (uint256) {
        uint256 priceInUSD = getPriceForNFT(tokenId);
        uint usdPerEth = dexExchange.getCurrentUsdcToEthPrice();
        return (priceInUSD * 1e18) / usdPerEth;
    }

    /**
     * @dev Sets the price for a specific NFT in USD
     * @param tokenId The ID of the NFT to set the price for
     * @param priceInUSD The price in USD (with 18 decimals)
     */
    function setNFTPrice(
        uint256 tokenId,
        uint256 priceInUSD
    ) external onlyOwner {
        if (priceInUSD == 0) {
            revert InvalidPrice();
        }

        // Verify the NFT is owned by the marketplace
        if (nftContract.ownerOf(tokenId) != address(this)) {
            revert NotOwnedByMarketplace();
        }

        nftPrices[tokenId] = priceInUSD;
        emit NFTPriceSet(tokenId, priceInUSD);
    }

    /**
     * @dev Sets the default price for NFTs in USD
     * @param newDefaultPrice The new default price in USD (with 18 decimals)
     */
    function setDefaultPrice(uint256 newDefaultPrice) external onlyOwner {
        if (newDefaultPrice == 0) {
            revert InvalidPrice();
        }

        uint256 oldPrice = defaultPrice;
        defaultPrice = newDefaultPrice;
        emit DefaultPriceUpdated(oldPrice, newDefaultPrice);
    }

    /**
     * @dev Returns the traits of an NFT that is listed on the marketplace
     * @param tokenId The ID of the NFT to query
     * @return The traits of the NFT as a string
     */
    function getNFTTraits(
        uint256 tokenId
    ) external view returns (string memory) {
        if (nftContract.ownerOf(tokenId) != address(this)) {
            revert NotOwnedByMarketplace();
        }
        return nftContract.getTraits(tokenId);
    }

    /**
     * @dev Returns the price in USD for a specific NFT
     * @param tokenId The ID of the NFT to query
     * @return The price in USD with 18 decimals precision
     */
    function getPriceForNFT(uint256 tokenId) public view returns (uint256) {
        uint256 specificPrice = nftPrices[tokenId];
        if (specificPrice > 0) {
            return specificPrice;
        }
        return defaultPrice;
    }

    /**
     * @dev Allows the owner to withdraw ETH from sales
     * @param amount The amount of ETH to withdraw
     */
    function withdrawETH(uint256 amount) external onlyOwner nonReentrant {
        // Check that there's enough ETH balance
        if (address(this).balance < amount) {
            revert ETHRefundFailed();
        }

        // Use a secure withdrawal pattern
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert ETHRefundFailed();
        }
    }

    // ------------------------------------------------------------------------
    //                    NFT Listing Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Helper function to remove a token from the listed tokens array
     * @param tokenId The ID of the NFT to remove from the listing
     */
    function _removeTokenFromListing(uint256 tokenId) private {
        for (uint i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                // Move the last element to the position of the element to delete
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                // Remove the last element
                listedTokenIds.pop();
                break;
            }
        }
    }

    /**
     * @dev Returns the number of NFTs currently listed on the marketplace
     * @return Number of listed NFTs
     */
    function getListedNFTCount() external view returns (uint256) {
        return listedTokenIds.length;
    }

    /**
     * @dev Returns the listed NFT IDs with pagination
     * @param startIndex The starting index for pagination
     * @param count The number of NFTs to return
     * @return Array of token IDs that are currently listed
     */
    function getListedNFTs(
        uint256 startIndex,
        uint256 count
    ) external view returns (uint256[] memory) {
        uint256 endIndex = startIndex + count;

        // Adjust endIndex if it exceeds array length
        if (endIndex > listedTokenIds.length || count == 0) {
            endIndex = listedTokenIds.length;
        }

        // Calculate actual count of NFTs to return
        uint256 actualCount = endIndex > startIndex ? endIndex - startIndex : 0;

        uint256[] memory result = new uint256[](actualCount);

        for (uint256 i = 0; i < actualCount; i++) {
            result[i] = listedTokenIds[startIndex + i];
        }

        return result;
    }

    /**
     * @dev Returns detailed information about listed NFTs with pagination
     * @param startIndex The starting index for pagination
     * @param count The number of NFTs to return
     * @return tokenIds Array of token IDs
     * @return prices Array of prices in USD (with 18 decimals)
     * @return pricesInEth Array of current prices in ETH
     * @return traits Array of NFT traits
     */
    function getListedNFTDetails(
        uint256 startIndex,
        uint256 count
    )
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256[] memory prices,
            uint256[] memory pricesInEth,
            string[] memory traits
        )
    {
        uint256 endIndex = startIndex + count;

        // Adjust endIndex if it exceeds array length
        if (endIndex > listedTokenIds.length || count == 0) {
            endIndex = listedTokenIds.length;
        }

        // Calculate actual count of NFTs to return
        uint256 actualCount = endIndex > startIndex ? endIndex - startIndex : 0;

        tokenIds = new uint256[](actualCount);
        prices = new uint256[](actualCount);
        pricesInEth = new uint256[](actualCount);
        traits = new string[](actualCount);

        // Get price once outside the loop to avoid multiple external calls
        uint usdPerEth = dexExchange.getCurrentUsdcToEthPrice();

        // Pre-fetch all token IDs to minimize gas costs and improve security
        uint256[] memory fetchedTokenIds = new uint256[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            fetchedTokenIds[i] = listedTokenIds[startIndex + i];
            tokenIds[i] = fetchedTokenIds[i];

            // Get USD price
            uint256 priceInUSD = getPriceForNFT(fetchedTokenIds[i]);
            prices[i] = priceInUSD;

            // Calculate ETH price
            pricesInEth[i] = (priceInUSD * 1e18) / usdPerEth;
        }

        // Now fetch traits in a separate loop to avoid external calls inside the first loop
        for (uint256 i = 0; i < actualCount; i++) {
            // Get traits
            traits[i] = nftContract.getTraits(fetchedTokenIds[i]);
        }

        return (tokenIds, prices, pricesInEth, traits);
    }

    /**
     * @dev Fallback function to receive ETH
     */
    receive() external payable {
        // Allow receiving ETH
    }
}
