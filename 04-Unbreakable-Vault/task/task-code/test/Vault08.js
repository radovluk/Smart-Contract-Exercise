const { expect } = require("chai");
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers');

/**
 * Test Suite for the Vault08: Tokens for Free
 */
describe("Vault08 Test Suite", function () {
    let vault;
    let player;
    let playerAddress;
    const PLAYER_INITIAL_ETH = ethers.parseEther("1"); // Starting ETH balance for player

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();
        playerAddress = await player.getAddress();

        // Deploy Vault contract
        vault = await ethers.deployContract("Vault08");
        await vault.waitForDeployment();

        console.log("Vault08 deployed at:", vault.target);
        console.log("Player address:", playerAddress);

        // Set up player's initial balances
        await setBalance(player.address, PLAYER_INITIAL_ETH);

        // Verify player's balance
        expect(await ethers.provider.getBalance(player.address)).to.equal(PLAYER_INITIAL_ETH);
    });

    /**
     * Test case for the player to breach the vault
     */
    it("Execution of the player's code", async function () {
        // =========================
        // TODO: YOUR CODE GOES HERE
        // Use only player account 
        // await vault.connect(player).breachVault();
        // =========================
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(playerAddress);

        // Expect the player to have at least 1,000,000 tokens
        expect(await vault.tokenBalances(playerAddress), "Player doesn't have enough tokens")
            .to.be.at.least(1_000_000);
    });
});