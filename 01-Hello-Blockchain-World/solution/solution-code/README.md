# Smart Contracts Exercise 01: Hello, Blockchain World!

Welcome to the first smart contracts exercise! In this exercise, you will become familiar with the basics of smart contract development. The goal is to create a simple smart contract, compile, test, and deploy it to a local network environment, and subsequently to a live blockchain.

## Prerequisites

Ensure you have the following installed:
- Node.js: [https://nodejs.org/en/](https://nodejs.org/en/)
- NPM: Comes with Node.js

## Setting Up Hardhat Environment

1. Initialize an npm project:
    ```bash
    npm init -y
    ```
2. Install Hardhat:
    ```bash
    npm install --save-dev hardhat
    ```
3. Initialize a Hardhat project:
    ```bash
    npx hardhat init
    ```

## Writing Your First Smart Contract

Create a file `contracts/Greeter.sol` with the following content:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
}
```

## Compiling the Contract

Compile the contract:
```bash
npx hardhat compile
```

## Testing the Contract

1. Install Hardhat Toolbox:
    ```bash
    npm install --save-dev @nomicfoundation/hardhat-toolbox
    ```
2. Create a file `test/Greeter.js` with the following content:
    ```javascript
    const { expect } = require("chai");

    describe("Greeter contract", function () {
        it("Deployment should set the initial greeting correctly.", async function () {
            const initialGreeting = "Hello, Blockchain World!";
            const greeter = await ethers.deployContract("Greeter", [initialGreeting]);
            await greeter.waitForDeployment();
            const greeting = await greeter.greet();
            expect(greeting).to.equal(initialGreeting);
        });
    });
    ```
3. Run the test:
    ```bash
    npx hardhat test
    ```

## Deploying to Sepolia Testnet

1. Install dotenv:
    ```bash
    npm install dotenv --save
    ```
2. Create a `.env` file with your Infura API key and private key:
    ```bash
    INFURA_API_KEY=your_infura_project_id
    SEPOLIA_PRIVATE_KEY=your_metamask_private_key
    ```
3. Update `hardhat.config.js`:
    ```javascript
    require("@nomicfoundation/hardhat-toolbox");
    require("dotenv").config();

    module.exports = {
        solidity: "0.8.0",
        networks: {
            sepolia: {
                url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
                accounts: [`0x${process.env.SEPOLIA_PRIVATE_KEY}`],
            },
        },
    };
    ```
4. Create a file `scripts/deploy.js` with the following content:
    ```javascript
    const hre = require("hardhat");

    async function main() {
        const initialGreeting = "Hello, Blockchain World!";
        const greeter = await ethers.deployContract("Greeter", [initialGreeting]);
        console.log(`Greeter contract deployed to: ${greeter.target}`);
        await greeter.waitForDeployment();
        const greeting = await greeter.greet();
        console.log(`Contract greeting: ${greeting}`);
    }

    main().then(() => process.exit(0)).catch((error) => {
        console.error(error);
        process.exit(1);
    });
    ```
5. Deploy the contract:
    ```bash
    npx hardhat run scripts/deploy.js --network sepolia
    ```

Congratulations! You have successfully deployed your first smart contract to the live blockchain network!
