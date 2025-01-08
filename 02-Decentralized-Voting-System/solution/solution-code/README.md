# Decentralized Voting System: Solution

## Project Structure

```
├── contracts
│   └── Voting.sol
├── hardhat.config.js
├── package.json
├── README.md
├── scripts
│   └── deploy.js
└── test
    └── Voting.js
```

## Overview

This project implements a decentralized voting system using Solidity. The contract allows the owner to add candidates and users to vote for them. Each user can vote only once.

## Setup

1. Install dependencies:
    ```bash
    npm install
    ```

2. Run tests:
    ```bash
    npx hardhat test
    ```

3. Deploy the contract:
    ```bash
    npx hardhat run scripts/deploy.js
    ```

For more details, refer to the inline comments and documentation within the code files.