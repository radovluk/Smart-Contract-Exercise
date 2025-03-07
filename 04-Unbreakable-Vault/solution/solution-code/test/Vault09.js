const { expect } = require("chai");

/**
 * Test Suite for the Vault09: Less Is More
 */
describe("Vault09 Test Suite", function () {
    let vault;
    let player;
    let playerAddress, deployerAddress;
    const PLAYER_INIT_TOKEN_BALANCE = 1; // Player's initial token balance

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Get test accounts
        [deployer, player] = await ethers.getSigners();
        playerAddress = await player.getAddress();
        deployerAddress = await deployer.getAddress();

        // Deploy Vault contract
        vault = await ethers.deployContract("Vault09", deployer);
        await vault.waitForDeployment();

        console.log("Vault09 deployed at:", vault.target);
        console.log("Player address:", playerAddress);

        // Send the initial token balance to player
        // First, deployer approves itself to transfer tokens
        await vault.connect(deployer).approve(playerAddress, PLAYER_INIT_TOKEN_BALANCE);
        await vault.connect(deployer).transferFrom(deployerAddress, playerAddress, PLAYER_INIT_TOKEN_BALANCE);
        
        // Verify player has received their initial token
        expect(await vault.tokenBalances(playerAddress)).to.equal(PLAYER_INIT_TOKEN_BALANCE);
        console.log("Player has", (await vault.tokenBalances(playerAddress)).toString(), "initial token");
    });

    /**
     * Test case for the player to breach the vault
     */
    it("Execution of the player's code", async function () {

        // Deploy the attacker contract from the player's account.
        attackVault = await ethers.deployContract("Vault09Attack", [vault.target], player);
        await attackVault.waitForDeployment();
        
        console.log("Exploit contract deployed at:", attackVault.target);
        
        // Player approves the exploit contract to spend any 2 tokens
        await vault.connect(player).approve(attackVault.target, 2);

        // Player transfers 1 token to the attack contract
        await vault.connect(player).transferFrom(playerAddress, attackVault.target, 1);

        // Execute the attack
        const tx = await attackVault.attack();
        await tx.wait();
        
        console.log("Player's token balance:", (await vault.tokenBalances(playerAddress)).toString());
        
        // Break the vault
        await vault.connect(player).breachVault();
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Expect the last solver to be the player
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(playerAddress);
    });
});