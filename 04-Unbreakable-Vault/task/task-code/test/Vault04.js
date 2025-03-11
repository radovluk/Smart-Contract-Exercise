// Importing Chai to use its asserting functions.
const { expect } = require("chai");
/**
 * Test Suite for the Vault04: Pseudo-Random Trap
 */
describe("Vault04 Test Suite", function () {
  let vault;
  let player;
  let success;

  before("Set up the challenge", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Get test accounts
    [deployer, player] = await ethers.getSigners();

    // Deploy Vault contract
    vault = await ethers.deployContract("Vault04");
    await vault.waitForDeployment();
  });

  /**
   * Test case to check if the player can breach the Vault04 contract using the AttackVault04 contract.
   */
  it("Execution of the player's code", async function () {
    /**
     * DO NOT CHANGE ANYTHING HERE
     * Code your solution in contracts/VaultAttack04.sol
     */

    // Deploy the attacker contract from the player's account.
    attackVault = await ethers.deployContract(
      "Vault04Attack",
      [vault.target],
      player
    );
    await attackVault.waitForDeployment();

    // Call the attack function from the attacker contract
    const tx = await attackVault.connect(player).attack();
    await tx.wait();

    // Check if the attack was successful
    success = await attackVault.attack.staticCall();
  });

  after("Success conditions", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Expect the last solver to be the player
    expect(await vault.lastSolver(), "Last solver is not the player").to.equal(
      player.address
    );
    // Expect the attack to be successful
    expect(success, "Attack was not successful").to.be.true;
  });
});
