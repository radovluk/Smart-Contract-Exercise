// Importing necessary modules
const { expect } = require("chai");

/**
 * Test Suite for the Vault06: Explorer
 */
describe("Vault06 Test Suite", function () {
  let vault;
  let player; // Signer representing the player
  let playerAddress; // Address of the player

  before("Set up the challenge", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // For the purpouse of this test switch to the Sepolia test network
    await hre.switchNetwork("sepolia");

    // Using ethers.getContractAt to load the contract interface at the desired address
    const vaultAddress = "0xA3a763bF62550511A0E485d6EB16c98937609A32";
    const vaultAbi = [
      "function breachVault(string memory _password) public returns (bool)",
      "function lastSolver() public view returns (address)",
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
    // Read the storage slot value (32 bytes)
    let slotValue = await ethers.provider.getStorage(vault.target, 1);
    // Replace the last byte with 0x00 so that it becomes a valid bytes32 string:
    slotValue = slotValue.substring(0, slotValue.length - 2) + "00";
    const password = ethers.decodeBytes32String(slotValue);
    console.log("Storage value at slot", 1, ":", password);

    // Call breachVault with recovered password
    const tx = await vault.breachVault(password);
    await tx.wait();
  });

  after("Success conditions", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Expect the last solver to be the player
    // Verify lastSolver == your wallet address
    expect(await vault.lastSolver(), "Last solver is not the player").to.equal(
      playerAddress
    );

    // Switch back to Hardhat Network
    await hre.switchNetwork("hardhat");
  });
});
