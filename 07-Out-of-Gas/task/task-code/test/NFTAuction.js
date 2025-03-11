const { expect } = require("chai");
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers');

/**
 * Test Suite for the NFT Auction Challenge
 */
describe("NFT Auction Challenge", function () {
    let nftAuction;
    let deployer, seller, player, bidder1, bidder2;
    let felStudentNFT, tokenId;

    const INITIAL_PRICE = ethers.parseEther("0.5"); // 0.5 ETH initial price
    const PLAYER_INITIAL_ETH_BALANCE = ethers.parseEther("2"); // 2 ETH
    const BIDDER1_INITIAL_ETH_BALANCE = ethers.parseEther("4"); // 4 ETH
    const BIDDER2_INITIAL_ETH_BALANCE = ethers.parseEther("5"); // 5 ETH

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        [deployer, seller, player, bidder1, bidder2, bidder3] = await ethers.getSigners();

        // Deploy the FELStudentNFT contract
        const FELStudentNFT = await ethers.getContractFactory("FELStudentNFT", deployer);
        felStudentNFT = await FELStudentNFT.deploy();

        // Find indexes for the specific traits
        // Program: EK (index 1)
        // Sleep: Dozed Off (index 2)
        // Tool: Kalkulacka (index 4)
        const programIndex = 1;  // EK
        const sleepIndex = 2;    // Dozed Off
        const toolIndex = 4;     // Kalkulacka

        // Mint the NFT with the specific traits to the seller
        const mintTx = await felStudentNFT.connect(deployer).mint(
            seller.address,
            programIndex,
            sleepIndex,
            toolIndex
        );

        // Get tokenId from mint event
        tokenId = 1; // FELStudentNFT starts with ID 1

        // Deploy the auction contract with initial price
        const NFTAuction = await ethers.getContractFactory("NFTAuction", deployer);
        nftAuction = await NFTAuction.deploy(
            seller.address,
            felStudentNFT.target,
            tokenId,
            INITIAL_PRICE
        );

        // Now approve the auction contract to transfer the NFT
        await felStudentNFT.connect(seller).approve(nftAuction.target, tokenId);
    
        // Transfer the NFT to the auction contract
        await felStudentNFT.connect(seller).transferFrom(seller.address, nftAuction.target, tokenId);

        console.log("Player address: ", player.address);
        console.log("Seller address: ", seller.address);
        console.log("Auction address", nftAuction.target);

        // Get auction details to verify setup
        const auctionInfo = await nftAuction.getAuctionedNFT();
        console.log("Auction Details:");
        console.log("- NFT Contract:", auctionInfo[0]);
        console.log("- Token ID:", auctionInfo[1]);
        console.log("- Token Description:", auctionInfo[3]);
        console.log("- Current Price:", ethers.formatEther(auctionInfo[4]), "ETH");
        console.log("- Starting Price:", ethers.formatEther(auctionInfo[5]), "ETH");

        // Set up the inital balance of the player
        await setBalance(player.address, PLAYER_INITIAL_ETH_BALANCE);
        await setBalance(bidder1.address, BIDDER1_INITIAL_ETH_BALANCE);
        await setBalance(bidder2.address, BIDDER2_INITIAL_ETH_BALANCE);

        // Set up some initial bids
        console.log("Bidder 1 bids 1.0 ETH");
        await nftAuction.connect(bidder1).bid({ value: ethers.parseEther("1.0") });

        console.log("Bidder 2 bids 2.0 ETH");
        await nftAuction.connect(bidder2).bid({ value: ethers.parseEther("2.0") });

        console.log("Bidder 1 bids 2.5 ETH");
        await nftAuction.connect(bidder1).bid({ value: ethers.parseEther("2.5") });

        console.log("Bidder 2 bids 2.8 ETH");
        await nftAuction.connect(bidder2).bid({ value: ethers.parseEther("2.8") });

        // Verify biddder2 is the highest bidder
        expect(await nftAuction.highestBidder()).to.equal(bidder2.address);
        expect(await nftAuction.highestBid()).to.equal(ethers.parseEther("2.8"));
    });

    it("Execution of the player's code", async function () {
        // =========================
        // TODO: YOUR CODE GOES HERE
        // =========================
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Bidder 3 tries to overbid everyone
        console.log("Bidder 3 bids 50 ETH to overbid everyone");
        await nftAuction.connect(bidder3).bid({ value: ethers.parseEther("50") });

        // Deployer tries to end the auction
        try {
            await nftAuction.connect(deployer).endAuction();
            console.log("ERROR: Auction ending should have failed!");
        } catch (error) {
            console.log("Successfully blocked auction from ending!");
            console.log("All bidder funds and the NFT are now stuck in the contract forever!");
            const stuckFunds = await ethers.provider.getBalance(nftAuction.target);
            console.log(`Total stuck funds: ${ethers.formatEther(stuckFunds)} ETH`);
        }

        // Verify that the NFT is not owned by the bidder 3
        expect(await felStudentNFT.ownerOf(tokenId), "The bidder 3 should not own the NFT!").to.not.equal(bidder3.address);

        // Verify the NFT is still owned by the auction contract
        expect(await felStudentNFT.ownerOf(tokenId), "NFT should remain with the auction contract").to.equal(nftAuction.target);

        // Verify the auction is still active
        expect(await nftAuction.ended(), "Auction should still be active").to.be.false;

        // Check bidder balances are reduced by their bids
        const bidder1Balance = await ethers.provider.getBalance(bidder1.address);
        const bidder2Balance = await ethers.provider.getBalance(bidder2.address);

        // Calculate total bids from each bidder
        const bidder1TotalBid = ethers.parseEther("1.0") + ethers.parseEther("2.5");
        const bidder2TotalBid = ethers.parseEther("2.0") + ethers.parseEther("2.8");

        // Verify bidders have lost their funds (balances are reduced by their bids)
        expect(bidder1Balance,  "Bidder1 balance should be reduced by the sum of his bids").to.be.lessThanOrEqual(BIDDER1_INITIAL_ETH_BALANCE - bidder1TotalBid);
        expect(bidder2Balance, "Bidder2 balance should be reduced by the sum of his bids").to.be.lessThanOrEqual(BIDDER2_INITIAL_ETH_BALANCE - bidder2TotalBid);

        // Verify contract balance includes all bids
        const contractBalance = await ethers.provider.getBalance(nftAuction.target);
        expect(contractBalance, "Contract balance should greater the sum of the bids").to.be.greaterThan(bidder1TotalBid + bidder2TotalBid);
    });
});