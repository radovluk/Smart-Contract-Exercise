const { expect } = require("chai");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * Test for the NFT Auction Frontrunning Challenge
 */
describe("NFT Auction Frontrunning Challenge", function () {
  let felStudentNFT, auction;
  let deployer, player, bidder1, bidder2;
  let tokenId;

  /**
   * Constants for the challenge
   * Do not change their values!
   */
  const STARTING_PRICE = ethers.parseEther("0.5"); // 0.5 ETH starting price
  const PLAYER_BALANCE = ethers.parseEther("1.51"); // 1.51 ETH for the player

  before("Set up the challenge", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Get signers
    [deployer, player, bidder1, bidder2] = await ethers.getSigners();

    console.log(`Deployer: ${deployer.address}`);
    console.log(`Player: ${player.address}`);
    console.log(`Bidder 1: ${bidder1.address}`);
    console.log(`Bidder 2: ${bidder2.address}`);

    console.log("Setting up the FEL Student NFT Collection...");
    // Deploy NFT Collection
    const FELStudentNFT = await ethers.getContractFactory(
      "FELStudentNFT",
      deployer
    );
    felStudentNFT = await FELStudentNFT.deploy();
    await felStudentNFT.waitForDeployment();

    console.log(`FEL Student NFT deployed to: ${felStudentNFT.target}`);

    // Set player's balance
    await setBalance(player.address, PLAYER_BALANCE);
    console.log(
      `Player's balance set to ${ethers.formatEther(PLAYER_BALANCE)} ETH`
    );

    // Set up the auction contract first (we need its address to mint the NFT directly to it)
    console.log("Setting up the auction contract...");
    const NFTAuction = await ethers.getContractFactory("NFTAuction", deployer);
    auction = await NFTAuction.deploy(
      deployer.address, // Set deployer as the seller
      felStudentNFT.target,
      1, // tokenId will be 1
      STARTING_PRICE
    );
    await auction.waitForDeployment();
    console.log(`Auction contract deployed to: ${auction.target}`);

    // Mint an NFT directly to the auction contract
    // - a student with OES program, Sleepwalking status, and Laptop tool
    console.log("Minting NFT directly to the auction contract...");
    const mintTx = await felStudentNFT.mint(
      auction.target, // Mint directly to auction contract
      5, // OES program
      6, // Sleepwalking
      0 // Laptop
    );

    // Wait for mint transaction to complete
    const receipt = await mintTx.wait();
    tokenId = 1; // First token ID is 1

    console.log(`FEL Student NFT minted with ID: ${tokenId}`);
    const traits = await felStudentNFT.getTraits(tokenId);
    console.log(`NFT Traits: ${traits}`);

    // Verify the NFT is owned by the auction contract
    const nftOwner = await felStudentNFT.ownerOf(tokenId);
    console.log(`NFT is now owned by: ${nftOwner}`);
    expect(nftOwner).to.equal(
      auction.target,
      "Auction contract should own the NFT"
    );

    // Set up initial bids
    await auction.connect(bidder1).bid({ value: ethers.parseEther("1.0") });
    console.log("Bidder 1 placed a bid of 1.0 ETH");

    await auction.connect(bidder2).bid({ value: ethers.parseEther("1.5") });
    console.log("Bidder 2 placed a bid of 1.5 ETH");

    mine(1); // Mine a block to ensure bids are processed

    // Get current fee data for EIP-1559 transaction
    const feeData = await ethers.provider.getFeeData();

    // Instead of directly calling endAuction, we'll prepare a transaction
    const endAuctionTx = await deployer.populateTransaction({
      to: auction.target,
      data: auction.interface.encodeFunctionData("endAuction"),
      type: 2, // EIP-1559 transaction
      maxFeePerGas: feeData.maxFeePerGas,
      maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
    });

    // Send the transaction
    await deployer.sendTransaction(endAuctionTx);
    console.log("Deployer is sending a transaction to end the auction...");
  });

  it("Execution of the player's code", async function () {
    // =========================
    // TODO: YOUR CODE GOES HERE
    // Hint 1: https://docs.ethers.org/v6/api/transaction/
    // Hint 2: Follow EIP-1559 transaction structure
    // Hint 3: Do not forget to include gasLimit
    // Hint 4: use exploreMempoolTransactions() function to see the mempool
    // const pendingBlock = await network.provider.send("eth_getBlockByNumber", [
    //   "pending",
    //   false,
    // ]);
    // targetTx = await exploreMempoolTransactions(
    //   pendingBlock.transactions,
    //   <contract>,
    //   <target_function>
    // );
    // =========================
  });

  after("Success conditions", async function () {
    /** DO NOT CHANGE ANYTHING HERE */

    // Wait for a block to mine
    await mine(1);

    // Seller claims the funds
    await auction.connect(deployer).claimFunds();
    console.log("Seller claimed the funds");

    // Verify that the player is now the owner of the NFT
    const nftOwner = await felStudentNFT.ownerOf(tokenId);
    expect(nftOwner, "Player should now own the NFT").to.equal(player.address);

    // Get the final price paid
    const finalPrice = await auction.highestBid();
    console.log(`Final price paid: ${ethers.formatEther(finalPrice)} ETH`);
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
        console.log(`Arguments: ${JSON.stringify(decodedFunction.args)}`);

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

          // Store the target transaction details for return
          targetTx = {
            hash: txHash,
            from: tx.from,
            to: tx.to,
            maxFeePerGas: tx.maxFeePerGas,
            maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
            // For EIP-1559, we don't use gasPrice
            gasLimit: tx.gasLimit,
            data: tx.data,
            value: tx.value,
            type: tx.type,
            function: decodedFunction.name,
            args: decodedFunction.args,
          };
        }
      } catch (e) {
        console.log(`Failed to decode transaction data: ${e.message}`);
      }
    }
  }

  return targetTx;
}
