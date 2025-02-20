// Importing Chai to use its asserting functions.
const { expect } = require("chai");

/**
 * Test Suite for the Vault05: Fortune Teller
 */
describe("Vault05 Test Suite", function () {
    let vault;
    let player;

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();

        // Deploy Vault contract
        vault = await ethers.deployContract("Vault05");
        await vault.waitForDeployment();
    });

    /**
     * Here's where you try to breach the vault.
     * Fill in your logic to figure out the guess and call the breachVault function.
     */
    it("Execution of the player's code", async function () {
        // =========================
        // TODO: YOUR CODE GOES HERE
        // Use only player account 
        // await vault.connect(player).lockInGuess(<GUESS>);
        // await vault.connect(player).breachVault();
        // =========================
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(player.address);
    });
});
