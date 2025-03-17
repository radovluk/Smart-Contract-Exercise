# Decentralized Voting System: Solution

## Project Structure

```
├── src
│   └── Voting.sol           # Main contract
├── test
│   └── Voting.t.sol         # Tests for the Voting contract
├── script
│   └── Deploy.s.sol         # Deployment script
├── foundry.toml             # Foundry configuration
├── .env                     # For environment variables (optional)
├── README.md                # Project documentation
└── remappings.txt           # For import remappings
└── package.json             # Dependecy specification
```

## Overview

This project implements a decentralized voting system using Solidity. The contract allows the owner to add candidates and users to vote for them. Each user can vote only once.

## Setup

1. Install dependencies:
    ```bash
    bun install
    ```

2. Run tests:
    ```bash
    forge test
    ```

3. Deploy the contract:
    ```bash
    forge script script/Deploy.s.sol --rpc-url <your-rpc-url> --private-key <your-private-key> --broadcast
    ```

For more details, refer to the inline comments and documentation within the code files.