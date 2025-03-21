const { expect } = require("chai");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * Test Suite for the Cat Charity Hijinks Challenge
 */
describe("CatCharity Challenge", function () {
  let catCharity;
  let deployer, player;

  const CHARITY_INITIAL_BALANCE = ethers.parseEther("10"); // 10 ETH
  const PLAYER_INITIAL_ETH_BALANCE = ethers.parseEther("1"); // 1 ETH

  before("Set up the challenge", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    [deployer, player] = await ethers.getSigners();

    // Deploy charity and send the first donation
    catCharity = await (
      await ethers.getContractFactory("CatCharity", deployer)
    ).deploy();
    await catCharity.donate({ value: CHARITY_INITIAL_BALANCE });

    // Verify that charity starts with 10 ETH
    expect(await ethers.provider.getBalance(catCharity.target)).to.equal(
      CHARITY_INITIAL_BALANCE
    );

    // Player starts with 2 ETH in balance
    await setBalance(player.address, PLAYER_INITIAL_ETH_BALANCE);
    expect(await ethers.provider.getBalance(player.address)).to.eq(
      PLAYER_INITIAL_ETH_BALANCE
    );

    // The owner (deployer) cancels the campaign, allowing refunds
    await catCharity.connect(deployer).cancelCampaign();
    // Verify that campaign is canceled
    expect(await catCharity.isCanceled()).to.be.true;
  });

  it("Execution of the player's code", async function () {
    // 1) The player deploys the Attacker contract
    catAttacker = await (
      await ethers.getContractFactory("CatAttacker", deployer)
    ).deploy(catCharity.target);

    // 2) The player calls `attack()` with a small donation to set up re-entrancy
    //    We'll donate 0.5 ETH
    await catAttacker
      .connect(player)
      .attack({ value: ethers.parseEther("0.5") });

    // By the end of this transaction, the attacker contract's fallback
    // will keep calling `claimRefund()` in a loop until the charity is drained.
  });

  after("Success conditions", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // The CatCharity contract balance should now be 0
    const finalBalance = await ethers.provider.getBalance(catCharity.target);
    expect(finalBalance, "Cat charity was not fully drained").to.equal(0);

    // The player should have more then the initial charity balance
    // He has less then (10 ETH) + the initial player balance (1 ETH) because of gas the costs
    expect(
      await ethers.provider.getBalance(player.address),
      "The player should have more then the initial charity balance"
    ).to.gt(CHARITY_INITIAL_BALANCE);
  });
});
