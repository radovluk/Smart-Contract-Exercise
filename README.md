# Smart Contracts Exercises

## Overview

This project contains exercises for students to learn about smart contract security. Each exercise includes a task and a solution, with explanations provided.

## Structure

```
├── Exercise name
│   ├── solution
│   │   ├── solution-code
│   │   └── solution-explanation
│   └── task
│       ├── task-code
│       └── task-instructions
└── README.md
```

### Folder Structure

- **Exercise name**: Each exercise has its own directory.
    - **solution**
        - **solution code**: The fully implemented solution for the exercise.
        - **solution explanation**: Additional explanations if needed. PDF and .tex source code.
    - **task**
        - **task code**: Templates for students to complete.
        - **task instructions**: Instructions in PDF and .tex source code format.
- **README.md**: The main README file for the project.

## Exercises

### 01 - Hello Blockchain World
- **Task**: In this first exercise, you will become familiar with the basics of smart contract development. The goal is to create a simple smart contract. You will then compile, test, and deploy this smart contract in the local network environment, and subsequently deploy it to the live blockchain.
- **Topics**: Hardhat, MetaMask, Infura, Sepolia, Etherscan

### 02 - Decentralized Voting System
- **Task**: In this exercise, you will implement a decentralized voting system on the blockchain. This will be a simple smart contract that allows address owners to vote for individual candidates and subsequently display the voting results. The goal of this exercise is to familiarize yourself with the basics of the Solidity language.
- **Topics**: Solidity programming

### 03 - ERC-20 CTU Token
- **Task**: In this exercise, you will learn about tokens on Ethereum, with a particular focus on ERC-20 fungible tokens. You will implement a smart contract that follows the ERC-20 standard. In the second part of the exercise, you will focus on a Frontrunning attack targeting your CTU token contract. Finally, you will need to consider changes to the implementation to mitigate the risk of a frontrunning attack.
- **Topics**: Frontrunning Attack, ERC-20, ERC-1155, ERC-721, OpenZeppelin

### 04 - Unbreakable Vault
In this exercise, you will be tasked with breaching several vaults, one by one in CTF style. You will gain familiarity with the JavaScript library Ethers.js, which is designed to facilitate interaction with the Ethereum blockchain and its ecosystem. We will also demonstrate how to work in Remix IDE, an open-source development environment accessible through a web browser. Additionally, you will learn about blockchain data transparency, the differences between msg.sender and tx.origin, and how to predict blockhash or block.timestamp in certain scenarios.
- **Topics**: Ethers.js, Remix IDE, storage, blockhash, timestamp, tx.origin, msg.sender

## Getting Started

1. Clone the repository.
2. Navigate to the exercise directory.
3. Follow the task instructions to complete the exercise.
4. Refer to the solution for guidance and explanations.

## Contributing

Feel free to submit issues or pull requests if you find any bugs or have suggestions for improvements.