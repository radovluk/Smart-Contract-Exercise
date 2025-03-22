// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTAuction
 * @notice This contract implements an auction for a NFT:
 *         - Users can place bids during the bidding period
 *         - When outbid, previous bidders can be refunded by calling withdraw() function
 *         - The owner can end the auction and distribute funds to the seller
 *         - The highest bidder receives the auctioned NFT
 *         - The previous bids are automatically refunded at the end of the auction
 */
contract NFTAuction is Ownable {
    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    // Address of the seller who is selling the NFT
    address public immutable seller;

    // The current highest bidder
    address public highestBidder;

    // The current highest bid amount
    uint256 public highestBid;

    // The initial price of the NFT
    uint256 public immutable initialPrice;

    // Whether the auction has ended
    bool public ended;

    // The NFT contract address
    IERC721 public immutable nftContract;

    // The ID of the NFT being auctioned
    uint256 public immutable tokenId;

    // Mapping of pending returns for outbid bidders
    mapping(address => uint256) public pendingReturns;

    // Mapping of bidders to check if they have already bid
    mapping(address => bool) public hasBid;

    // List of all bidders for record keeping
    address[] public bidders;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    // Emitted when a new bid is placed
    event BidPlaced(address indexed bidder, uint256 amount);

    // Emitted when the auction ends
    event AuctionEnded(address indexed winner, uint256 amount);

    // Emitted when a refund is processed
    event RefundProcessed(address indexed bidder, uint256 amount);

    // Emitted when auction ends without NFT transfer due to lack of approval
    event AuctionEndedWithoutTransfer(
        address indexed highestBidder,
        uint256 amount
    );

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// Auction has already ended
    error AuctionAlreadyEnded();

    /// Bid is not high enough
    error BidNotHighEnough(uint256 highestBid);

    /// Only the owner can call this function
    error OnlyOwner();

    /// Seller does not own the NFT
    error SellerNotOwner();

    /// Zero address not allowed
    error ZeroAddressNotAllowed();

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------

    /**
     * @dev Sets up the auction for any NFT
     * @param _seller The address of the seller who is selling the NFT
     * @param _nftContract The address of the NFT contract
     * @param _tokenId The ID of the NFT being auctioned
     * @param _initialPrice The starting price for the NFT auction
     */
    constructor(
        address _seller,
        address _nftContract,
        uint256 _tokenId,
        uint256 _initialPrice
    ) Ownable(msg.sender) {
        if (_seller == address(0)) revert ZeroAddressNotAllowed();
        if (_nftContract == address(0)) revert ZeroAddressNotAllowed();

        seller = _seller;
        nftContract = IERC721(_nftContract);
        tokenId = _tokenId;
        initialPrice = _initialPrice;
        highestBid = _initialPrice; // Set the minimum bid to the initial price
        ended = false;

        // Ensure the seller owns the token
        if (nftContract.ownerOf(_tokenId) != _seller) revert SellerNotOwner();
    }

    // ------------------------------------------------------------------------
    //                          Contract Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Places a bid on the auctioned NFT.
     * - To place a bid, send Ether to this function with an amount greater than the current highest bid.
     * - Your previous bid will be refunded if you are outbid by calling the withdraw() function.
     * - If you outbid yourself, your previous bids will be refunded when the auction ends.
     */
    function bid() external payable {
        // Check if auction is still active
        if (ended) revert AuctionAlreadyEnded();

        // Check if bid is high enough
        if (msg.value <= highestBid) revert BidNotHighEnough(highestBid);

        // Process the previous highest bidder's refund
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        // Update highest bid information
        highestBidder = msg.sender;
        highestBid = msg.value;

        // Add to bidders list if not already there
        if (!hasBid[msg.sender]) {
            bidders.push(msg.sender);
            hasBid[msg.sender] = true;
        }

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @dev Withdraws a refund for a specific bidder.
     * - You can call this function to withdraw your refund after being outbid.
     * @return True if the withdrawal was successful
     */
    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Set pending amount to zero first to prevent re-entrancy
            pendingReturns[msg.sender] = 0;

            // Send the refund
            payable(msg.sender).transfer(amount);
            emit RefundProcessed(msg.sender, amount);
        }
        return true;
    }

    /**
     * @dev Ends the auction, transfers the NFT to the highest bidder, and sends the funds to the seller.
     * - Called by the owner when the auction duration has passed.
     * - Automatically refunds any previous bids.
     * - If NFT approval is not granted, returns funds to the highest bidder instead.
     */
    function endAuction() external onlyOwner {
        // Check if the auction has already ended
        if (ended) revert AuctionAlreadyEnded();

        // Mark the auction as ended
        ended = true;

        // Process refunds for all bidders
        for (uint i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            uint256 amount = pendingReturns[bidder];
            if (amount > 0) {
                // Important: Setting the pending amount to 0 before sending to prevent re-entrancy
                pendingReturns[bidder] = 0;

                // Send the refund
                payable(bidder).transfer(amount);
                emit RefundProcessed(bidder, amount);
            }
        }

        // Contract is approved, transfer the NFT to the highest bidder
        nftContract.transferFrom(address(this), highestBidder, tokenId);

        // NFT transfer succeeded, now transfer funds to the seller
        payable(seller).transfer(highestBid);

        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
     * @dev Allows to check the total number of bidders.
     * @return The number of unique bidders
     */
    function getBidderCount() external view returns (uint256) {
        return bidders.length;
    }

    /**
     * @dev Returns information about the NFT being auctioned.
     * @notice You can use this function to view details about the NFT currently being auctioned,
     *         including its contract address, token ID, owner, URI for metadata, and current price.
     * @return nftAddress The address of the NFT contract
     * @return nftId The ID of the NFT being auctioned
     * @return nftOwner The current owner of the NFT (should be the seller)
     * @return nftURI The URI of the NFT metadata if the contract supports it
     * @return currentPrice The current highest bid (or initial price if no bids yet)
     * @return startingPrice The initial price set when the auction started
     */
    function getAuctionedNFT()
        external
        view
        returns (
            address nftAddress,
            uint256 nftId,
            address nftOwner,
            string memory nftURI,
            uint256 currentPrice,
            uint256 startingPrice
        )
    {
        nftAddress = address(nftContract);
        nftId = tokenId;
        nftOwner = nftContract.ownerOf(tokenId);
        currentPrice = highestBid;
        startingPrice = initialPrice;

        // Try to get token URI if the contract supports metadata extension
        try IERC721Metadata(nftAddress).tokenURI(tokenId) returns (
            string memory uri
        ) {
            nftURI = uri;
        } catch {
            nftURI = "";
        }

        return (
            nftAddress,
            nftId,
            nftOwner,
            nftURI,
            currentPrice,
            startingPrice
        );
    }
}
