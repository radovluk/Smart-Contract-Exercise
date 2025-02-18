// Importing necessary modules
const { expect } = require("chai");

/**
 * Test Suite for the Vault06 contract.
 */
describe("Vault06 Test Suite", function () {
    let vault;
    let player; // Signer representing the player
    let playerAddress; // Address of the player

    before(async function () {
        /** SET UP - DO NOT CHANGE ANYTHING HERE */

        // For the purpouse of this test switch to the Sepolia test network
        await hre.switchNetwork("sepolia");

        // Using ethers.getContractAt to load the contract interface at the desired address
        const vaultAddress = "0xA3a763bF62550511A0E485d6EB16c98937609A32";
        const vaultAbi = [
            "function breachVault(string memory _password) public returns (bool)",
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
    it("Player's attempt: Breach the Vault06", async function () {
        // =========================
        // YOUR CODE GOES HERE
        // Use your sepolia account to call breachVault with the correct password
        // Example:
        // const password = "your_password_here";
        // Call breachVault with recovered password
        // const tx = await vault.breachVault(password);
        // await tx.wait();
        // =========================

        /** SUCCESS CONDITIONS - DO NOT CHANGE ANYTHING HERE */
        // Verify lastSolver == your wallet address
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(playerAddress);
    });
});
