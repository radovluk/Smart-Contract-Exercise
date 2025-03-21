const { expect } = require("chai");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * Test Suite for the CTUTokenBank Challenge
 */
describe("CTUTokenBank Challenge", function () {
  let deployer, player;
  let token, bank;

  const BANK_INITIAL_ETH_BALANCE = ethers.parseEther("10"); // 10 ETH
  const PLAYER_INITIAL_ETH_BALANCE = ethers.parseEther("5.1"); // 5.1 ETH
  const CTU_TOKEN_INITIAL_SUPPLY = ethers.parseEther("1000000"); // 1 million tokens

  before("Set up the challenge", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Get signers
    [deployer, player] = await ethers.getSigners();

    // Deploy the CTUToken contract
    token = await (
      await ethers.getContractFactory("CTUToken", deployer)
    ).deploy();

    // Deploy the CTUTokenBank contract, passing it the CTUToken address
    bank = await (
      await ethers.getContractFactory("CTUTokenBank", deployer)
    ).deploy(token.target);

    // Transfer all tokens from deployer to the bank
    await token
      .connect(deployer)
      .transfer(bank.target, CTU_TOKEN_INITIAL_SUPPLY);
    expect(await token.balanceOf(bank.target)).to.equal(
      CTU_TOKEN_INITIAL_SUPPLY
    );

    // Set the bank’s initial ETH balance
    await setBalance(bank.target, BANK_INITIAL_ETH_BALANCE);
    expect(await ethers.provider.getBalance(bank.target)).to.equal(
      BANK_INITIAL_ETH_BALANCE
    );

    // Give the player 5.1 ETH to start with
    await setBalance(player.address, PLAYER_INITIAL_ETH_BALANCE);
    expect(await ethers.provider.getBalance(player.address)).to.eq(
      PLAYER_INITIAL_ETH_BALANCE
    );
  });

  it("Execution of the player's code", async function () {
    // Deploy the attack contract
    const attackerContractFactory = await ethers.getContractFactory(
      "CTUTokenBankAttacker",
      player
    );
    const attackerContract = await attackerContractFactory.deploy(
      bank.target,
      token.target
    );

    // Execute the attack with 5 Ethers
    await attackerContract.attack({ value: 5n * 10n ** 18n });
  });

  after("Success conditions", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // The bank's balance should be 0 if the exploit succeeded
    const bankFinalBal = await ethers.provider.getBalance(bank.target);
    console.log("Final Bank Balance: ", bankFinalBal.toString());

    // The player should hold nearly all the bank’s ETH (minus some gas costs).
    const playerBalance = await ethers.provider.getBalance(player.address);
    console.log("Final Player Balance:", playerBalance.toString());

    // Check final conditions (assuming the exploit succeeded)
    expect(bankFinalBal).to.equal(0, "Bank was not fully drained!");
    expect(playerBalance).to.be.gt(
      15,
      "Player did not gain funds from the bank"
    );
  });
});
