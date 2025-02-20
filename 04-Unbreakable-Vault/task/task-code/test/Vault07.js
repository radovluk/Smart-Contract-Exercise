// Importing necessary modules
const { expect } = require("chai");

/**
 * Test Suite for the Vault07: You Shall Not Pass!
 */
describe("Vault07 Test Suite", function () {
    let vault;
    let player; // Signer representing the player
    let playerAddress; // Address of the player
    let vaultAddress; // Address of the vault contract

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

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
    it("Execution of the player's code", async function () {
        // =========================
        // TODO: YOUR CODE GOES HERE
        // Use your sepolia account to call breachVault with the correct password
        // Example:
        // const password = "your_password_here";
        // Call breachVault with recovered password
        // const tx = await vault.breachVault(password);
        // await tx.wait();
        // =========================
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Expect the last solver to be the player
         // Verify lastSolver == your wallet address
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(playerAddress);
    });
});
