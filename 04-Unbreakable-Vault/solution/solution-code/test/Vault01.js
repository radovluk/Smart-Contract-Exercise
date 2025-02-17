// Importing Chai to use its asserting functions.
const { expect } = require("chai");

/**
 * Test Suite for the Vault01 contract.
 */
describe("Vault01 Test Suite", function () {
    let vault;
    let deployer, player;

    before(async function () {
         /** SET UP - DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();

        // Deploy Vault contract
        vault = await ethers.deployContract("Vault01");
        await vault.waitForDeployment();
    });

    /**
     * Here's where you try to breach the vault.
     * Fill in your logic to figure out the password and call the breachVault function.
     */
    it("Player's attempt: Breach the Vault01", async function () {
        
        // =========================
        // YOUR CODE GOES HERE
        // A simple hashing function which operates on UTF-8 strings to compute an 32-byte identifier.
        // This simply computes the UTF-8 bytes and computes the keccak256.
        // See https://docs.ethers.org/v6/api/hashing/ for more.
        const hash = ethers.id("password");
        console.log("Hash of the password is: ", hash);
        await vault.connect(player).breachVault(hash);
        // =========================


         /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(player.address);
    });
});
