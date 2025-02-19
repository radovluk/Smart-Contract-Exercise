// Importing necessary modules
const { expect } = require("chai");

/**
 * Test Suite for the Vault07 contract.
 */
describe("Vault07 Test Suite", function () {
    let vault;
    let player; // Signer representing the player
    let playerAddress; // Address of the player
    let vaultAddress; // Address of the vault contract

    before(async function () {
        /** SET UP - DO NOT CHANGE ANYTHING HERE */

        // For the purpouse of this test switch to the Sepolia test network
        await hre.switchNetwork("sepolia");

        // Using ethers.getContractAt to load the contract interface at the desired address
        vaultAddress = "0xa81C96B2216eDFfF8945e371dd581D13f8ECfbAD";
        const vaultAbi = [
            "function breachVault(bytes32 _password) public returns (bool)",
            "function lastSolver() public view returns (address)"
        ];
        vault = await ethers.getContractAt(vaultAbi, vaultAddress);

        // Retrieve the list of signers
        [player] = await ethers.getSigners();

        // Get the player's address
        playerAddress = await player.getAddress();

        // Now you can call functions on the vault contract as if you're on Sepolia
        console.log("Contract loaded from forked Sepolia network at", vaultAddress);
        console.log("Player's address:", playerAddress);
    });

    /**
     * Here's where you try to breach the vault.
     * Fill in your logic to figure out the password and call the breachVault function.
     */
    it("Player's attempt: Breach the Vault07", async function () {
        // =========================
        // TODO: YOUR CODE GOES HERE
        // =========================

        // /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        // // Verify lastSolver == our wallet address
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(playerAddress);
    });
});
