# Smart Contracts Exercise 01: Hello, Blockchain World!

Welcome to the first smart contracts exercise! In this first exercise, you will become familiar with the basics of smart contract development. The goal is to create a simple smart contract. You will then compile, test, and deploy this smart contract in the local network, and subsequently deploy it to the live blockchain.

## Task: Set Up Hardhat Environment

In this task, you will set up the Hardhat development environment. Hardhat is a development environment for Ethereum software. It provides a suite of tools for editing, compiling, debugging, and deploying your smart contracts. For this exercise, you can choose between using a Docker container or installing locally on your machine - select the option that best suits your development preferences.

### Using Docker with VS Code

This option uses Docker to create a development environment with all the necessary tools and dependencies pre-installed.

#### Prerequisites:

- [Docker](https://www.docker.com/products/docker-desktop) - A platform for developing, shipping, and running applications in containers.
- [Visual Studio Code](https://code.visualstudio.com/) - A lightweight but powerful source code editor.
- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) - An extension to VS Code that lets you use a Docker container as a full-featured development environment.

#### Setting Up the Project:

1. Visit the following [GitLab repository](https://gitlab.fel.cvut.cz/radovluk/smart-contracts-exercises/-/tree/main/01-Hello-Blockchain-World/task/task-code) and clone it to your local machine.
2. Open the repository folder in VS Code.
3. When prompted, click "Reopen in Container" or use the command palette (F1) and run `Dev Containers: Reopen in Container`.

Note: If you encounter permission issues when using Docker, you may need to adjust file permissions or run Docker with appropriate privileges. On Linux systems, you might need to add your user to the docker group: `sudo usermod -aG docker $USER` and then log out and back in.

### Local Setup

If you prefer working directly on your machine without Docker, you can set up the development environment locally. Before setting up Hardhat, ensure that you have the following installed on your system:

#### Prerequisites
- **Node.js** - https://nodejs.org/en/ - An open-source, cross-platform, back-end JavaScript runtime environment that runs on the V8 engine and executes JavaScript code outside a web browser.
- **NPM**: Node Package Manager, which comes with Node.js.

Open your terminal and run the following commands to verify the installations:

```bash
$ node -v
$ npm -v
```

Both commands should return the installed version numbers of Node.js and NPM respectively. Node.js provides the runtime environment required to execute JavaScript-based tools like Hardhat, while NPM is used to manage the packages and dependencies needed for development.

- **Tip 1:** If you are using Windows, we strongly recommend using Windows Subsystem for Linux (WSL) to follow this guide. For more information, refer to the [official documentation](https://learn.microsoft.com/en-us/windows/wsl/about).
    
- **Tip 2:** If you are using Visual Studio Code, consider installing the [Visual Studio Code Solidity Extension](https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity). This extension helps your development process by providing features like syntax highlighting, code completion, etc.

### Creating a New Hardhat Project

Create an empty working directory and then run the following commands to initialize a Hardhat project:

```bash
$ npm init -y # Initialize an npm project in the directory.
$ npm install --save-dev hardhat # Install Hardhat in the directory.
$ npx hardhat init # Initialize a Hardhat project.
```

Select `Create an empty hardhat.config.js` with your keyboard and hit enter.

## Task: Writing Your First Smart Contract

Start by creating a new directory inside your project called `contracts` and create a file inside the directory called `Greeter.sol`. Paste the code below into the file and take a minute to read the code.

```solidity
// File: contracts/Greeter.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // Specify the Solidity compiler version

/**
 * @title Greeter
 * @dev A simple smart contract that stores a greeting message.
 */
contract Greeter {
    string private greeting; // State variable to store the greeting message

    /**
    * @dev Constructor that sets the initial greeting message upon deployment.
     * @param _greeting The greeting message to be stored.
     */
    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    /**
     * @dev Function to retrieve the greeting message.
     * @return The current greeting stored in the contract.
     */
    function greet() public view returns (string memory) {
        return greeting;
    }
}
```

The Greeter contract is a simple Solidity smart contract that stores a greeting message, initializes it during deployment, and allows users to retrieve it via a public function. To compile the contract, run `npx hardhat compile` in your terminal.

```bash
$ npx hardhat compile
Compiled 1 Solidity file successfully (evm target: paris).
```

Hardhat compiled your Solidity smart contract and generated corresponding artifacts—including the contract's ABI (Application Binary Interface, which defines how to interact with the contract), bytecode (the compiled binary code that runs on the Ethereum Virtual Machine), and related metadata—which are stored in the `artifacts` folder. Take a look into `artifacts/contracts/Greeter.sol/Greeter.json` file.

## Task: Test your Smart Contract with Local Hardhat Network

### Set Up Hardhat-Toolbox Plugin
In this task, you will write and execute a simple test case for the `Greeter` contract using Hardhat's local network. For this task, we will need the `@nomicfoundation/hardhat-toolbox` plugin. It integrates testing libraries, Ethers.js, and other deployment utilities. Run the following command in the directory to install the plugin:

```bash
$ npm install --save-dev @nomicfoundation/hardhat-toolbox
```

To include the plugin in your Hardhat project, add the following to your `hardhat.config.js` file in the project directory so that it will look like this:

```javascript
// File: hardhat.config.js

require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
};
```

For more information about plugins and how to test contracts in Hardhat, visit [Hardhat documentation](https://hardhat.org/tutorial/testing-contracts).

### Writing a Simple Test

Create a new directory named `test` in your project root and add a file called `Greeter.js` with the following content:

```javascript
// File: test/Greeter.js

// Import the 'expect' function from Chai for assertions
const { expect } = require("chai");

// Test suite for the Greeter contract
describe("Greeter contract says Hello, Blockchain World!", function () {
  
  // Test to ensure the initial greeting is set correctly upon deployment
  it("Should set the initial greeting correctly.", async function () {
    
    // Define the initial greeting message
    const initialGreeting = "Hello, Blockchain World!";
    
    // Deploy the Greeter contract with the initial greeting
    const greeter = await ethers.deployContract("Greeter", [initialGreeting]);
    
    // Wait for the deployment to complete
    await greeter.waitForDeployment();

    // Retrieve the stored greeting from the contract
    const greeting = await greeter.greet();

    // Verify that the retrieved greeting matches the initial greeting
    expect(greeting).to.equal(initialGreeting);
  });
});
```

**Note:** All exercises we will use [ethers.js v6](https://docs.ethers.org/v6/). If you're using an older version of ethers, the syntax may differ. For example, in ethers v5, you would use `await ethers.getContractFactory("Greeter")` and then `await greeterFactory.deploy(initialGreeting)` instead. Keep this in mind when encountering errors.

### Running the Test

Execute the test on Hardhat's local network by running the following commands in your terminal:

```bash
$ npx hardhat test
```

Congratulations! You wrote, compiled, and tested your first smart contract!

## Task: Deploying to a Live Network

Once you have programmed and tested your dApp, you want to deploy it to a public blockchain so that others can access it. For the purposes of our exercise, we will not use the Ethereum mainnet because we would have to pay with real money, but instead use a live testnet. A testnet mimics real-world scenarios without risking our own money. Ethereum has several [testnets](https://ethereum.org/en/developers/docs/networks/#ethereum-testnets); for our purposes, we will choose the [Sepolia testnet](https://sepolia.dev/). Deploying to a testnet is the same as deploying to mainnet at the software level. The only difference is the network you connect to.

### Prerequisites

In order to finish this task, you will need the following tools:

- **MetaMask**: A popular Ethereum wallet that allows you to interact with the Ethereum blockchain. You can download the MetaMask extension for your browser from the [official website](https://metamask.io/) and set it up. But you can also use other Ethereum wallets or simply create your own private-public key pair.
    
- **Infura API Key**: Infura provides access to Ethereum nodes without the need to run your own. Sign up at [Infura](https://infura.io/) to obtain an API key.
    
- **Sepolia Faucet**: Acquire Sepolia test Ether from a faucet to fund your deployment. Even on testnets, you'll need testnet ETH to pay for gas fees. Make sure you have enough Sepolia ETH (0.01 Sepolia ETH should be sufficient for this exercise) in your wallet before deployment. Gas prices fluctuate based on network congestion, even on testnets. Some reliable faucets include:
  - [Google Cloud Web3](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)
  - [Metamask Sepolia Faucet](https://docs.metamask.io/developer-tools/faucet/)
  - [Alchemy Sepolia Faucet](https://www.alchemy.com/faucets/ethereum-sepolia)

### Configuring Hardhat for Sepolia Deployment

To deploy your smart contract to the Sepolia testnet, you need to configure Hardhat with the network details and your wallet credentials.

#### Storing Sensitive Information

It's crucial to keep sensitive information like your private key and Infura API key secure. We recommend using configuration variables to manage these credentials only for the purpose of this exercise. A Hardhat project can use configuration variables for user-specific values or for data that shouldn't be included in the code repository. These variables are set via tasks in the vars scope and can be retrieved in the config using the vars object.

First, install the Hardhat vars plugin:

```bash
$ npm install --save-dev @nomicfoundation/hardhat-vars
```

Then set the required variables:

- Set the INFURA_API_KEY
    
```bash
$ npx hardhat vars set INFURA_API_KEY
Enter value: ********************************
```

- Set the SEPOLIA_PRIVATE_KEY

```bash
$ npx hardhat vars set SEPOLIA_PRIVATE_KEY
Enter value: ********************************
```

**Warning**: Configuration variables are stored in plain text on your disk. Avoid using this feature for data you wouldn't normally save in an unencrypted file. Run `npx hardhat vars path` to find the storage's file location. Never use your private key associated with real money in plain text!

#### Updating `hardhat.config.js`

Modify your `hardhat.config.js` file to include the Sepolia network configuration:

```javascript
// File: hardhat.config.js

require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-vars");

const INFURA_API_KEY = vars.get("INFURA_API_KEY");
const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`0x${SEPOLIA_PRIVATE_KEY}`],
    },
  },
};
```

This configuration tells Hardhat how to connect to the Sepolia testnet using your Infura API key and deploy contracts using your wallet's private key.

### Deploying the Smart Contract to Sepolia

With the configuration in place, you're ready to deploy your smart contract to the Sepolia testnet.

#### Creating a Deployment Script

1. Create a `scripts` Directory: In your project root, create a new directory named `scripts`.

2. Add a Deployment Script: Inside the `scripts` directory, create a file named `deploy.js` and add the following content:

```javascript
// File: scripts/deploy.js

const hre = require("hardhat");

async function main() {
    console.log("Starting deployment process...");
    
    try {
        // Set the initial greeting message
        const initialGreeting = "Hello, Blockchain World!";
        console.log(`Using initial greeting: "${initialGreeting}"`);
        
        // Get the network information
        const network = hre.network.name;
        console.log(`Deploying to network: ${network}`);
        
        // Deploy the Greeter contract with the initial greeting
        console.log("Deploying Greeter contract...");
        const greeter = await ethers.deployContract("Greeter", [initialGreeting]);
        
        // Wait for the deployment to complete
        console.log("Waiting for deployment confirmation...");
        await greeter.waitForDeployment();
        
        // Get contract details
        const deployedAddress = await greeter.getAddress();
        const deployTx = greeter.deploymentTransaction();
        
        // Display deployment details
        console.log("\n----- DEPLOYMENT SUCCESSFUL -----");
        console.log(`Network: ${network}`);
        console.log(`Contract address: ${deployedAddress}`);
        console.log(`Transaction hash: ${deployTx.hash}`);
        
        // Verify the contract is working
        const greeting = await greeter.greet();
        console.log(`Contract greeting: "${greeting}"`);
        
        // Provide next steps for verification if on a testnet
        if (network !== "hardhat" && network !== "localhost") {
            console.log("\n----- NEXT STEPS -----");
            console.log(`Verify your contract on ${network} explorer:`);
            console.log(`npx hardhat verify --network ${network} ${deployedAddress} "${initialGreeting}"`);
        }
    } catch (error) {
        console.error("\n----- DEPLOYMENT FAILED -----");
        console.error(error);
        process.exit(1);
    }
}

// Execute the deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Unhandled error during deployment:");
        console.error(error);
        process.exit(1);
    });
```

#### Executing the Deployment

Run the deployment script using Hardhat with the Sepolia network specified:

```bash
$ npx hardhat run scripts/deploy.js --network sepolia
```

Expected Output:
```
Starting deployment process...
Using initial greeting: "Hello, Blockchain World!"
Deploying to network: sepolia
Deploying Greeter contract...
Waiting for deployment confirmation...

----- DEPLOYMENT SUCCESSFUL -----
Network: sepolia
Contract address: <ContractAddress>
Transaction hash: <TransactionHash>
Contract greeting: "Hello, Blockchain World!"

----- NEXT STEPS -----
Verify your contract on sepolia explorer:
npx hardhat verify --network sepolia <ContractAddress> "Hello, Blockchain World!"
```

You can verify the deployment by visiting the Sepolia Etherscan explorer and searching for your contract address: https://sepolia.etherscan.io/address/<ContractAddress>. Search also for your account address and see your interactions with the deployed contract.

Note that transactions on testnets may take longer to process than on local networks. Your deployment might take anywhere from 15 seconds to several minutes to confirm, depending on network congestion.

Hardhat also includes Hardhat network, a local Ethereum network node for development. It enables you to deploy contracts, run tests, and debug code, all within your local environment. We already used it during running our test. To use it, open a separate terminal and run `npx hardhat node` in the terminal. To deploy the contract, run `npx hardhat run scripts/deploy.js --network hardhat` in another terminal. See [Hardhat network](https://hardhat.org/hardhat-network/docs/overview#hardhat-network) for more information.

### Verifying Your Contract on Etherscan

After deployment, verify your contract code on Etherscan to allow others to view and interact with it:

```bash
# 1. Install the Hardhat Etherscan plugin:
$ npm install --save-dev @nomicfoundation/hardhat-verify

# 2. Add to your hardhat.config.js:
require("@nomicfoundation/hardhat-verify");

module.exports = {
  // other config
  etherscan: {
    apiKey: vars.get("ETHERSCAN_API_KEY"),
  },
};

# 3. Set your Etherscan API key:
$ npx hardhat vars set ETHERSCAN_API_KEY

# 4. Verify your contract:
$ npx hardhat verify --network sepolia <CONTRACT_ADDRESS> "Hello, Blockchain World!"
```

### Common Deployment Issues

- **Insufficient Funds**: Ensure you have enough Sepolia ETH for deployment.  
   Error: "Error HH9: TransactionExecutionError: [UNPREDICTABLE_GAS_LIMIT]"  
   Solution: Get more testnet ETH from a faucet.

- **Network Connectivity**: Check your connection to Infura.  
   Error: "Error HH10: ConnectionTimedOutError"  
   Solution: Verify your API key and network status at https://status.infura.io/

- **Contract Size Limit**: Very large contracts may exceed size limits.  
   Error: "Error HH406: Contract code size exceeds 24576 bytes"  
   Solution: Optimize your contract or split it into multiple contracts.

### Interacting with Your Deployed Contract

Now that your contract is live on the Sepolia testnet, you can interact with it using various tools:

- **Etherscan**: View contract details, read functions, and execute transactions directly from the Etherscan interface.
    
- **Web3 Interfaces**: Integrate your contract with frontend applications using libraries like `ethers.js` or `web3.js`.
    
- **Hardhat Tasks**: Write scripts or use the [Hardhat console](https://hardhat.org/hardhat-runner/docs/guides/hardhat-console) to interact programmatically with your contract.

Tip: If you run the deployment script without specifying the `--network` parameter, it will deploy to the local Hardhat network.
```bash
$ npx hardhat run scripts/deploy.js
```

## Further Reading

For more detailed information, refer to the following resources:

- [Solidity Documentation](https://docs.soliditylang.org/en/latest/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [Solidity by Example](https://solidity-by-example.org/)
- [Ethers.js Documentation](https://docs.ethers.org/v6/) (for scripting)
- [Chai Assertion Library](https://www.chaijs.com/)

Congratulations! You have successfully deployed your first smart contract to the live blockchain network! Stay tuned for the upcoming exercises!
