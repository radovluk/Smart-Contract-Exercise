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
- **Task**: In this exercise, you will be tasked with breaching several vaults, one by one in CTF style. You will gain familiarity with the JavaScript library Ethers.js. We will also demonstrate how to work in Remix IDE, an open-source development environment accessible through a web browser. Additionally, you will learn about insecure randomness, commit and reveal scheme, blockchain data transparency, the differences between msg.sender and tx.origin and integer underflow and overflow problem.
- **Topics**: Ethers.js, Remix IDE, insecure randomness, commit and reveal, storage, blockhash, timestamp, tx.origin, msg.sender, integer underflow, integer overflow

### 05 - Re-Entrancy
- **Task**: Re-entrancy is one of the most damaging vulnerabilities in Ethereum's history. This well-documented type of attack gained notoriety in 2016 with the infamous DAO hack. In this exercise, you will learn how to identify and exploit various types of re-entrancy attacks, as well as implement proper mitigation strategies.
- **Topics**: single-function re-entrancy, cross-function re-entrancy, cross-contract re-entrancy, read-only re-entrancy, DAO, mutex, CEI pattern

### 06 - Fool the Oracle
- **Task**: Oracles are essential components in decentralized applications that require external data. In this exercise, you will become familiar with both synchronous and asynchronous types of oracles, learn about the concept of decentralized exchanges, and understand their use as on-chain oracles. Finally, you will practically implement a price oracle manipulation attack using a flash loan.
- **Topics**: asynchronous oracle, synchronous oracle, AMMs, DEX, liquidity pool, stable coin, USDC, constant product, slippage, flashloan

### 07 - Out of Gas
- **Task**: Denial of Service attacks in smart contracts aim to render a contract temporarily or permanently unusable by manipulating its execution flow or exploiting resource limitations. In this exercise, you will learn about several types of DoS attacks on blockchain and try to implement them in practical exercises. You will also become familiar with the concept of decentralized autonomous organization.
- **Topics**: DoS with block gas limit, DoS with unexpected revert, pull-over-push pattern, unbounded operations, DAO
- 
### 08 - Maximal Extractable Value
- **Task**: In this exercise, we examine MEV (Maximal Extractable Value) in detail, exploring techniques like DEX arbitrage, liquidations, and sandwich trading. We also cover transaction fees, gas calculations, and EIP-1559. In practical tasks, you'll frontrun an NFT auction and execute a sandwich attack on a DEX. We will also mention current MEV solutions including Proposer-Builder Separation.
- **Topics**: MEV, frontrunning, backrunning, sandwich attacks, transaction fees, gas, EIP-1559, DEX arbitrage, liquidations, proposer-builder separation

## Getting Started

1. Clone the repository.
2. Navigate to the exercise directory.
3. Follow the task instructions to complete the exercise.
4. Refer to the solution for guidance and explanations.

## Contributing

Feel free to submit issues or pull requests if you find any bugs or have suggestions for improvements.