// Importing Chai to use its asserting functions.
const { expect } = require("chai");

/**
 * Test Suite for the Vault01 contract.
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

        // The vault should be locked initially
        await expect(vault.connect(player).steal()).to.be.revertedWith("Vault is not unlocked");
    });

    /**
     * Here's where you try to unlock the vault.
     * Fill in your logic to figure out the password or call `unlock` with the correct parameter.
     */
    it("Player's attempt: Unlock the Vault02", async function () {

        // =========================
        // YOUR CODE GOES HERE
        // Use player account to call unlock with the correct value
        // await vault.connect(player).unlock(<PASSWORD>);
        
        // See https://docs.ethers.org/v6/api/hashing/ for more.
        // Using ethers.solidityPacked to mimic abi.encodePacked(msg.sender)
        const encodedAddress = ethers.solidityPacked(["address"], [player.address]);

        // Hash the encoded address using keccak256
        const hash = ethers.keccak256(encodedAddress);

        // Call unlock with the derived value
        await vault.connect(player).unlock(hash);
        // =========================

        /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        expect(await vault.unlocked(), "Vault is not unlocked").to.equal(true);
    });
});
