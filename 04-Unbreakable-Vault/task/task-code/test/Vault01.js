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

        // The vault should be locked initially
        await expect(vault.connect(player).steal()).to.be.revertedWith("Vault is not unlocked");
    });

    /**
     * Here's where you try to unlock the vault.
     * Fill in your logic to figure out the password or call `unlock` with the correct parameter.
     */
    it("Player's attempt: Unlock the Vault01", async function () {
        
        // =========================
        // YOUR CODE GOES HERE
        // Use player account to call unlock with the correct value
        // await vault.connect(player).unlock(<PASSWORD>);

        // Use player account to call unlock with the correct value
        // A simple hashing function which operates on UTF-8 strings to compute an 32-byte identifier.
        // This simply computes the UTF-8 bytes and computes the keccak256.
        // See https://docs.ethers.org/v6/api/hashing/ for more.
        const hash = ethers.id("password");
        await vault.connect(player).unlock(hash);
        // =========================

         /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        expect(await vault.unlocked(), "Vault is not unlocked").to.equal(true);
    });
});
