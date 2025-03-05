const { expect } = require("chai");
const { ethers } = require("hardhat");
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers');

/**
 * Test Suite for Fool the Oracle Challenge 01
 */
describe("Fool the Oracle Challenge 01", function () {
    // Contract instances
    let usdcToken;
    let studentNFT;
    let simpleDEX;
    let nftMarketplace;

    // Actors
    let deployer, player;

    // Constants
    const INITIAL_LIQUIDITY_ETH = ethers.parseEther("1"); // Initial ETH liquidity of the DEX
    const INITIAL_LIQUIDITY_USDC = ethers.parseEther("2000"); // Initial USDC liquidity of the DEX
    const PLAYER_INITIAL_ETH = ethers.parseEther("0.8"); // Starting ETH balance for player
    const PLAYER_INITIAL_USDC = ethers.parseEther("3000"); // Starting USDC balance for player
    const NFT_PRICE_IN_USD = ethers.parseEther("5000"); // Default NFT price (will be overridden)
    const NFT_COUNT = 3; // Number of NFTs to steal

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */
        [deployer, player] = await ethers.getSigners();

        console.log("Deploying contracts...");

        // Deploy USDC Token
        const USDCToken = await ethers.getContractFactory("USDCToken", deployer);
        usdcToken = await USDCToken.deploy(ethers.parseEther("1000000")); // 1M USDC initial supply

        // Deploy SimpleDEX (our price oracle)
        const SimpleDEX = await ethers.getContractFactory("SimpleDEX", deployer);
        simpleDEX = await SimpleDEX.deploy(usdcToken.target);

        // Add initial liquidity to DEX
        await usdcToken.approve(simpleDEX.target, INITIAL_LIQUIDITY_USDC);
        await simpleDEX.addLiquidity(INITIAL_LIQUIDITY_USDC, { value: INITIAL_LIQUIDITY_ETH });

        // Log initial price and liquidity
        console.log("Initial price and liquidity on the DEX:");
        console.log(`ETH liquidity: ${ethers.formatEther(INITIAL_LIQUIDITY_ETH)} ETH`);
        console.log(`USDC liquidity: ${ethers.formatEther(INITIAL_LIQUIDITY_USDC)} USDC`);
        const initialPrice = await simpleDEX.getCurrentUsdcToEthPrice();
        console.log(`Initial exchange rate: 1 ETH = ${ethers.formatEther(initialPrice)} USDC`);

        // Deploy FEL Student NFT
        const FELStudentNFT = await ethers.getContractFactory("FELStudentNFT", deployer);
        studentNFT = await FELStudentNFT.deploy();

        // Deploy NFT Marketplace
        const NFTMarketplace = await ethers.getContractFactory("FELStudentNFTMarketplace", deployer);
        nftMarketplace = await NFTMarketplace.deploy(
            simpleDEX.target,
            studentNFT.target,
            usdcToken.target
        );

        // Create custom trait combinations for variety
        const nftTraits = [
            { program: 4, sleep: 1, tool: 1 },  // OI, Sleep Deprived, Skripta
            { program: 2, sleep: 3, tool: 2 },  // BIO, Pulling All-Nighter, Energy Drink
            { program: 3, sleep: 0, tool: 6 }   // KYR, Caffeinated, ChatGPT
        ];

        // Mint NFTs with specific traits
        for (let i = 0; i < NFT_COUNT; i++) {
            await studentNFT.mint(
                deployer.address,
                nftTraits[i].program,
                nftTraits[i].sleep,
                nftTraits[i].tool
            );
        }

        // Set default NFT price in USD
        await nftMarketplace.setDefaultPrice(NFT_PRICE_IN_USD);

        // List NFTs in the marketplace with different prices
        const nftPrices = [
            ethers.parseEther("5000"),  // NFT #1: 5,000 USDC (2.5 ETH)
            ethers.parseEther("8000"),  // NFT #2: 8,000 USDC (4.0 ETH)
            ethers.parseEther("3000")   // NFT #3: 3,000 USDC (1.5 ETH)
        ];

        console.log("\n=== FEL STUDENT NFT MARKETPLACE LISTINGS ===");

        for (let i = 1; i <= NFT_COUNT; i++) {
            // Give the NFTs to market place and set individual price for each NFT
            await studentNFT.approve(nftMarketplace.target, i);
            await nftMarketplace.receiveNFT(i);
            await nftMarketplace.setNFTPrice(i, nftPrices[i - 1]);

            // Get traits and current ETH price
            const traits = await nftMarketplace.getNFTTraits(i);
            const ethPrice = await nftMarketplace.getCurrentPriceForNFT(i);

            // Extract trait values for display
            const traitParts = traits.split(", ");
            const program = traitParts[0].split(": ")[1];
            const sleep = traitParts[1].split(": ")[1];
            const tool = traitParts[2].split(": ")[1];

            // Output in descriptive format
            console.log(`\nNFT #${i}`);
            console.log(`  ID: ${i}`);
            console.log(`  Program: ${program}`);
            console.log(`  Sleep Status: ${sleep}`);
            console.log(`  Study Tool: ${tool}`);
            console.log(`  Price (USD): ${ethers.formatEther(nftPrices[i - 1])}`);
            console.log(`  Price (ETH): ${ethers.formatEther(ethPrice)}`);
        }

        console.log("\nTotal ETH value of all NFTs:", ethers.formatEther(
            await nftMarketplace.getCurrentPriceForNFT(1) +
            await nftMarketplace.getCurrentPriceForNFT(2) +
            await nftMarketplace.getCurrentPriceForNFT(3)
        ), "ETH");

        // Verify NFTs are listed
        const listedCount = await nftMarketplace.getListedNFTCount();
        expect(listedCount).to.equal(NFT_COUNT);
        console.log(`All ${listedCount} FEL Student NFTs are available for purchase in the marketplace.`);

        // Set up player's initial balances
        await setBalance(player.address, PLAYER_INITIAL_ETH);
        await usdcToken.transfer(player.address, PLAYER_INITIAL_USDC);

        // Verify player's balance
        expect(await ethers.provider.getBalance(player.address)).to.equal(PLAYER_INITIAL_ETH);
        expect(await usdcToken.balanceOf(player.address)).to.equal(PLAYER_INITIAL_USDC);

        // Calculate player's total assets in ETH equivalent
        const playerUsdcInEth = PLAYER_INITIAL_USDC * BigInt(1e18) / BigInt(initialPrice);
        const playerTotalEthValue = BigInt(PLAYER_INITIAL_ETH) + BigInt(playerUsdcInEth);

        console.log(`\nPlayer's starting assets:`);
        console.log(`- ETH: ${ethers.formatEther(PLAYER_INITIAL_ETH)} ETH`);
        console.log(`- USDC: ${ethers.formatEther(PLAYER_INITIAL_USDC)} USDC (worth ${ethers.formatEther(playerUsdcInEth)} ETH)`);
        console.log(`- Total value: ${ethers.formatEther(playerTotalEthValue)} ETH equivalent`);
    });

    it("Execution of the player's code", async function () {
        // =========================
        // TODO: YOUR CODE GOES HERE
        // =========================
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // 1. The player should own all NFTs
        for (let i = 1; i <= NFT_COUNT; i++) {
            expect(await studentNFT.ownerOf(i)).to.equal(
                player.address,
                `Player doesn't own NFT #${i}`
            );
        }

        // Get the final balances for logging
        const playerFinalBalance = await ethers.provider.getBalance(player.address);
        const finalUsdcBalance = await usdcToken.balanceOf(player.address);

        console.log(`\n=== ATTACK RESULTS ===`);
        console.log(`Player's final ETH balance: ${ethers.formatEther(playerFinalBalance)} ETH`);
        console.log(`Player's final USDC balance: ${ethers.formatEther(finalUsdcBalance)} USDC`);

        // The final price in the DEX after the attack
        const finalPrice = await simpleDEX.getCurrentUsdcToEthPrice();
        console.log(`Final price: 1 ETH = ${ethers.formatEther(finalPrice)} USDC`);
    });
});