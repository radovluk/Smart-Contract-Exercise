const { expect } = require("chai");
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers');

/**
 * Test Suite for the NFT Auction DoS Challenge
 */
describe("NFT Auction Challenge", function () {
    let nftAuction;
    let deployer, seller, player, bidder1, bidder2;
    let felStudentNFT, tokenId;

    const INITIAL_PRICE = ethers.parseEther("0.5"); // 0.5 ETH initial price
    const PLAYER_INITIAL_ETH_BALANCE = 3n * 10n ** 18n; // 2 ETH
    const BIDDER1_INITIAL_ETH_BALANCE = 4n * 10n ** 18n; // 4 ETH
    const BIDDER2_INITIAL_ETH_BALANCE = 5n * 10n ** 18n; // 5 ETH

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        [deployer, seller, player, bidder1, bidder2] = await ethers.getSigners();

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

        // Verify player is the highest bidder
        expect(await nftAuction.highestBidder()).to.equal(bidder2.address);
        expect(await nftAuction.highestBid()).to.equal(ethers.parseEther("2.8"));
    });

    it("Execution of the player's code", async function () {
        console.log("Starting DoS attack on NFT Auction...");

        // Deploy our attacker contract
        const NFTAuctionAttacker = await ethers.getContractFactory("NFTAuctionAttacker", player);
        const attackerContract = await NFTAuctionAttacker.deploy(nftAuction.target);
        console.log("Attacker contract deployed at:", attackerContract.target);

        // Place a small bid through our attacker contract
        // This will add our contract to the bidders list but won't make it the highest bidder
        // The bid must be higher than initial price but lower than highest bid
        await attackerContract.connect(player).attack({
            value: ethers.parseEther("2.9") // Higher then the last bid
        });
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Deployer tries to end the auction
        try {
            await nftAuction.connect(deployer).endAuction();
            console.log("ERROR: Auction ending should have failed!");
        } catch (error) {
            console.log("Successfully blocked auction from ending!");
            console.log("All bidder funds are now stuck in the contract forever!");
        }

        // Verify the NFT is still owned by the seller and hasn't been transferred
        const currentOwner = await felStudentNFT.ownerOf(tokenId);
        expect(currentOwner).to.equal(seller.address, "NFT owner should still be the seller");

        // Verify the auction is still active (endAuction failed due to DoS)
        expect(await nftAuction.ended()).to.be.false, "Auction should still be active";

        // Verify the NFT is still owned by the seller
        expect(await felStudentNFT.ownerOf(tokenId)).to.equal(seller.address, "NFT should remain with the seller");

        // Check bidder balances are reduced by their bids
        const bidder1Balance = await ethers.provider.getBalance(bidder1.address);
        const bidder2Balance = await ethers.provider.getBalance(bidder2.address);

        // Calculate total bids from each bidder
        const bidder1TotalBid = ethers.parseEther("1.0") + ethers.parseEther("2.5");
        const bidder2TotalBid = ethers.parseEther("2.0") + ethers.parseEther("2.8");

        // Verify bidders have lost their funds (balances are reduced by their bids)
        expect(bidder1Balance).to.be.lessThanOrEqual(BIDDER1_INITIAL_ETH_BALANCE - bidder1TotalBid,
            "Bidder1 balance should be reduced by the sum of his bids");
        expect(bidder2Balance).to.be.lessThanOrEqual(BIDDER2_INITIAL_ETH_BALANCE - bidder2TotalBid,
            "Bidder2 balance should be reduced by the sum of his bids");

        // Verify contract balance includes all bids
        const contractBalance = await ethers.provider.getBalance(nftAuction.target);
        expect(contractBalance).to.be.greaterThan(bidder1TotalBid + bidder2TotalBid,
            "Contract balance should greater the sum of the bids");
    });
});