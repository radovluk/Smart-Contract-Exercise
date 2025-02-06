/**
 * Main deployment script for the Voting smart contract.
 * 
 * This script deploys the Voting contract using the first signer account
 * provided by Hardhat Runtime Environment (hre). It logs the address of the
 * deployer and the deployed contract address.
 * 
 * @async
 * @function main
 * @returns {Promise<void>} - A promise that resolves when the deployment is complete.
 * 
 * @throws {Error} If there is an issue with the deployment process.
 * 
 * @example
 * To run this script, use the Hardhat command:
 * npx hardhat run scripts/deploy.js --network <network-name>
 */
async function main() {
    // Get the first signer account from Hardhat's ethers provider
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Get the contract factory for the Voting contract
    const Voting = await hre.ethers.getContractFactory("Voting");
    // Deploy the Voting contract
    const voting = await Voting.deploy();

    // Log the address of the deployed Voting contract
    console.log("Voting contract deployed to:", voting.target);
}

// Execute the main function and handle any errors
main()
    .then(() => process.exit(0)) // Exit the process if the deployment is successful
    .catch((error) => {
        console.error(error); // Log any errors that occur during deployment
        process.exit(1); // Exit the process with an error code
    });
