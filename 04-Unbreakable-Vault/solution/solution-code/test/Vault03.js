// Importing Chai to use its asserting functions.
const { expect } = require("chai");
/**
 * Test Suite for the Vault03 contract.
 */
describe("Vault03 Test Suite", function () {
    let vault;
    let deployer, player;

    before(async function () {
        /** SET UP - DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();

        // Deploy Vault contract
        vault = await ethers.deployContract("Vault03");
        await vault.waitForDeployment();
    });

    /**
     * Test case to check if the player can breach the Vault03 contract using the AttackVault03 contract.
     */
    it("Player's attempt: Breach the Vault03 via the Vault03Attack contract", async function () {
        /**
         * SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE
         * Code your solution in contracts/VaultAttack03.sol
         */
        
        // Deploy the attacker contract from the player's account.
        attackVault = await ethers.deployContract("Vault03Attack", [vault.target], player);
        await attackVault.waitForDeployment();

        // Call the attack function from the attacker contract
        const tx = await attackVault.connect(player).attack();
        await tx.wait();

        // Check if the attack was successful
        const success = await attackVault.attack.staticCall();
        expect(success, "Attack was not successful").to.be.true;

        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(player.address);
    });
});
