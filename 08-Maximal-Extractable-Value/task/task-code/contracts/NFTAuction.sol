// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTAuction
 * @notice This contract implements an auction for NFTs using strict pull pattern:
 *         - Users can place bids during the bidding period
 *         - Outbid users must withdraw their funds themselves
 *         - When the auction ends, the highest bidder must claim the NFT
 *         - The seller must withdraw their funds themselves
 *         - Fully implements pull pattern for all value transfers
 */
contract NFTAuction is Ownable, ReentrancyGuard {
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

    // Tracks if the NFT has been claimed by the winner
    bool public nftClaimed;

    // Tracks if the seller has withdrawn the funds
    bool public fundsWithdrawn;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    // Emitted when a new bid is placed
    event BidPlaced(address indexed bidder, uint256 amount);

    // Emitted when the auction ends
    event AuctionEnded(address indexed winner, uint256 amount);

    // Emitted when a user withdraws their pending returns
    event WithdrawnPendingReturns(address indexed bidder, uint256 amount);

    // Emitted when the winner claims the NFT
    event NFTClaimed(address indexed winner, uint256 tokenId);

    // Emitted when the seller claims the funds
    event FundsClaimed(address indexed seller, uint256 amount);

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// Auction has already ended
    error AuctionAlreadyEnded();

    /// Auction has not ended yet
    error AuctionNotEndedYet();

    /// Bid is not high enough
    error BidNotHighEnough(uint256 highestBid);

    /// Only the highest bidder can claim the NFT
    error NotHighestBidder();

    /// Only the seller can claim the funds
    error NotSeller();

    /// NFT has already been claimed
    error NFTAlreadyClaimed();

    /// Funds have already been withdrawn
    error FundsAlreadyWithdrawn();

    /// No funds to withdraw
    error NoFundsToWithdraw();

    /// Transfer failed
    error TransferFailed();

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
        seller = _seller;
        nftContract = IERC721(_nftContract);
        tokenId = _tokenId;
        initialPrice = _initialPrice;
        highestBid = _initialPrice; // Set the minimum bid to the initial price
        ended = false;
        nftClaimed = false;
        fundsWithdrawn = false;
    }

    // ------------------------------------------------------------------------
    //                          Contract Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Places a bid on the auctioned NFT.
     * - To place a bid, send Ether to this function with an amount greater than the current highest bid.
     * - If you are outbid, you can manually withdraw your funds using the withdraw() function.
     * - Implements strict pull pattern - previous bids are always added to pendingReturns.
     */
    function bid() external payable nonReentrant {
        // Check if auction is still active
        if (ended) {
            revert AuctionAlreadyEnded();
        }

        // Check if bid is high enough
        if (msg.value <= highestBid) {
            revert BidNotHighEnough(highestBid);
        }

        // If this address has a previous bid, add it to pendingReturns
        if (msg.sender == highestBidder) {
            pendingReturns[msg.sender] += highestBid;
        }

        // Process the previous highest bidder's refund
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        // Update highest bid information
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    /**
     * @dev Withdraws pending returns for the caller.
     * - This function follows the pull pattern for security.
     * @return True if the withdrawal was successful
     */
    function withdraw() external nonReentrant returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) {
            revert NoFundsToWithdraw();
        }

        // Set pending amount to zero first to prevent re-entrancy
        pendingReturns[msg.sender] = 0;

        // Send the funds
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // If the transfer fails, restore the pending return balance
            pendingReturns[msg.sender] = amount;
            revert TransferFailed();
        }

        emit WithdrawnPendingReturns(msg.sender, amount);
        return true;
    }

    /**
     * @dev Ends the auction without transferring the NFT or funds
     * - Called by the owner when the auction duration has passed.
     * - Winner must claim the NFT, and seller must withdraw funds separately.
     */
    function endAuction() external onlyOwner {
        // Check if the auction has already ended
        if (ended) {
            revert AuctionAlreadyEnded();
        }

        // Mark the auction as ended
        ended = true;

        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
     * @dev Allows the highest bidder to claim the NFT after the auction has ended
     * - Can only be called by the highest bidder after the auction has ended
     */
    function claimNFT() external nonReentrant {
        if (!ended) {
            revert AuctionNotEndedYet();
        }

        if (msg.sender != highestBidder) {
            revert NotHighestBidder();
        }

        if (nftClaimed) {
            revert NFTAlreadyClaimed();
        }

        // Mark as claimed
        nftClaimed = true;

        // Transfer the NFT
        nftContract.transferFrom(address(this), highestBidder, tokenId);

        emit NFTClaimed(highestBidder, tokenId);
    }

    /**
     * @dev Allows the seller to claim the auction funds after the auction has ended
     * - Can only be called by the seller after the auction has ended
     */
    function claimFunds() external nonReentrant {
        if (!ended) {
            revert AuctionNotEndedYet();
        }

        if (msg.sender != seller) {
            revert NotSeller();
        }

        if (fundsWithdrawn) {
            revert FundsAlreadyWithdrawn();
        }

        // Mark as withdrawn
        fundsWithdrawn = true;

        // Transfer the funds
        (bool success, ) = payable(seller).call{value: highestBid}("");
        if (!success) {
            revert TransferFailed();
        }

        emit FundsClaimed(seller, highestBid);
    }

    /**
     * @dev Returns information about the NFT being auctioned.
     * @return nftAddress The address of the NFT contract
     * @return nftId The ID of the NFT being auctioned
     * @return nftOwner The current owner of the NFT (should be this contract)
     * @return nftURI The URI of the NFT metadata if the contract supports it
     * @return currentPrice The current highest bid (or initial price if no bids yet)
     * @return startingPrice The initial price set when the auction started
     * @return auctionEnded Whether the auction has ended
     * @return nftIsClaimed Whether the NFT has been claimed
     */
    function getAuctionInfo()
        external
        view
        returns (
            address nftAddress,
            uint256 nftId,
            address nftOwner,
            string memory nftURI,
            uint256 currentPrice,
            uint256 startingPrice,
            bool auctionEnded,
            bool nftIsClaimed
        )
    {
        nftAddress = address(nftContract);
        nftId = tokenId;
        nftOwner = nftContract.ownerOf(tokenId);
        currentPrice = highestBid;
        startingPrice = initialPrice;
        auctionEnded = ended;
        nftIsClaimed = nftClaimed;

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
            startingPrice,
            auctionEnded,
            nftIsClaimed
        );
    }

    /**
     * @dev Get the highest bidder and their bid
     * @return winner The address of the highest bidder
     * @return winningBid The highest bid amount
     */
    function getHighestBid()
        external
        view
        returns (address winner, uint256 winningBid)
    {
        return (highestBidder, highestBid);
    }
}
