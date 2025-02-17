// Importing Chai to use its asserting functions.
const { expect } = require("chai");

/**
 * Test Suite for the Vault05 contract.
 */
describe("Vault05 Test Suite", function () {
    let vault;
    let deployer, player;

    before(async function () {
        /** SET UP - DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();

        // Deploy Vault contract
        vault = await ethers.deployContract("Vault05");
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
        // await vault.connect(player).lockInPassword(<PASSWORD>);
        // await vault.connect(player).breachVault();
        
        // blockhash(uint blockNumber) returns (bytes32): hash of the given block - only works for 256 most recent blocks
        // https://docs.soliditylang.org/en/latest/cheatsheet.html
        // Lock the password
        await vault.connect(player).lockInPassword(ethers.ZeroHash);

        // Mine 256 blocks
        for (let i = 0; i < 256; i++) {
            await ethers.provider.send("evm_mine", []);
        }

        // Call breachVault with the derived value
        await vault.connect(player).breachVault();
        // =========================

        /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        // Check if the attack was successful
        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(player.address);
    });
});
