// Importing Chai to use its asserting functions.
const { expect } = require("chai");

/**
 * Test Suite for the Vault02 contract.
 */
describe("Vault02 Test Suite", function () {
    let vault;
    let deployer, player;

    before(async function () {
        /** SET UP - DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();

        // Deploy Vault contract
        vault = await ethers.deployContract("Vault02");
        await vault.waitForDeployment();
    });

    /**
     * Here's where you try to breach the vault.
     * Fill in your logic to figure out the password and call the breachVault function.
     */
    it("Player's attempt: Breach the Vault02", async function () {

        // =========================
        // TODO: YOUR CODE GOES HERE
        // Use only player account to call breachVault with the correct value
        // await vault.connect(player).breachVault(<PASSWORD>);
        // =========================

        /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        // Check if the attack was successful
        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(player.address);
    });
});
