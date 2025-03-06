# Smart Contracts Exercise 02: Decentralized Voting System

## Introduction

This exercise focuses on implementing a smart contract for a decentralized voting system on the blockchain. The main goal is to familiarize yourself with the basics of the Solidity language.

## Project Setup

You have two options for working with this exercise:

### Using Docker with VS Code

This option uses Docker to create a development environment with all the necessary tools and dependencies pre-installed.

#### Prerequisites:
- [Docker](https://www.docker.com/products/docker-desktop) - A platform for developing, shipping, and running applications in containers.
- [Visual Studio Code](https://code.visualstudio.com/) - A lightweight but powerful source code editor.
- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) - An extension to VS Code that lets you use a Docker container as a full-featured development environment.

#### Setting Up the Project:
1. Visit the following [GitLab repository](https://gitlab.fel.cvut.cz/radovluk/smart-contracts-exercises/-/tree/main/02-Decentralized-Voting-System/task/task-code?ref_type=heads) and clone it to your local machine.
2. Open the repository folder in VS Code.
3. When prompted, click "Reopen in Container" or use the command palette (F1) and run `Dev Containers: Reopen in Container`.

### Local Setup

If you prefer working directly on your machine without Docker, you can set up the development environment locally.

#### Prerequisites:
- **Node.js** - https://nodejs.org/en/ - An open-source, cross-platform, back-end JavaScript runtime environment.
- **NPM**: Node Package Manager, which comes with Node.js.

Open your terminal and run the following commands to verify the installations:

```bash
$ node -v
$ npm -v
```

Both commands should return the installed version numbers of Node.js and NPM respectively.

#### Setting Up the Project:
1. Visit the following [GitLab repository](https://gitlab.fel.cvut.cz/radovluk/smart-contracts-exercises/-/tree/main/02-Decentralized-Voting-System/task/task-code?ref_type=heads) and clone it to your local machine.
2. Open a terminal and navigate to the project directory.
3. Install the project dependencies by running `npm install`.

## Task Specification: Voting Contract

Your implementation will be in the file `contracts/Voting.sol`. In this file, there are #TODO comments where you should implement the required functionality. To fulfill this task, you need to pass all the provided tests. You can run the tests with the following command:

```bash
$ npx hardhat test
```

There is also a deployment script in the `scripts` folder. You can deploy the contract to the local Hardhat network with the following command:

```bash
$ npx hardhat run scripts/deploy.js
```

### Overview

The **Voting** contract is a simple implementation of a voting system using Solidity. It allows the contract owner to add candidates, and any address to vote exactly once for a candidate. The contract includes the following functionalities:
- The contract owner can add candidates.
- Any address can vote exactly once for a candidate.
- The contract tracks the number of votes each candidate has received.
- The contract tracks whether an address has already voted.
- A function to get the total number of candidates.
- A function to retrieve a candidate's name and vote count by index.
- A function to get the index of the winning candidate.

## Solidity Crash Course

The **Voting** contract is designed to facilitate a decentralized voting system. Below are some Solidity code snippets that you might find useful for implementing the contract.

### State Variables

```solidity
// Address of the contract owner
address public owner;

// Dynamic array to store all candidates
Candidate[] public candidates;

// Mapping to track whether an address has already voted
mapping(address => bool) public hasVoted;
```

### Structs

```solidity
/**
 * @dev Struct to represent a candidate.
 * @param name The name of the candidate.
 * @param voteCount The number of votes the candidate has received.
 */
struct Candidate {
    string name;
    uint voteCount;
}
```

### Constructor

```solidity
constructor() {
  // The deployer of the contract is the owner
  owner = msg.sender;
}
```

### Events

```solidity
/**
 * @dev Event emitted when a vote is cast.
 * @param voter The address of the voter.
 * @param candidateIndex The index of the candidate voted for.
 */
event Voted(address indexed voter, uint indexed candidateIndex);

/**
 * @dev Event emitted when a new candidate is added.
 * @param name The name of the candidate to be added.
 */
event CandidateAdded(string name);
```

### Errors

```solidity
/// Only the owner can call this function.
error NotOwner();
/// The candidate name cannot be empty.
error EmptyCandidateName();

// revert if condition is not met
require(msg.sender == owner, NotOwner());

// revert statement
revert EmptyCandidateName();
```

### Modifiers

```solidity
// Modifier to restrict access to the contract owner
modifier onlyOwner() {
    require(msg.sender == owner, NotOwner());
    _; // Continue executing the function
}

function addCandidate(string memory name) public onlyOwner {
  // Only the contract owner can call this function
}
```

### Functionality Provided by Solidity

Here are some useful code snippets you might need:

```solidity
// Sender of the transaction
address sender = msg.sender;

// Amount sent with the transaction
uint amount = msg.value;

// Enforcing conditions
require(condition, CustomError());

// Casting arbitrary data to uint
uint number = uint(data);

// Empty address
address emptyAddress = address(0);

// Emit an event
emit EventName(parameters);
```

To see some more advanced smart contract examples, visit the [Solidity by Example](https://docs.soliditylang.org/en/latest/solidity-by-example.html) section of the Solidity documentation.
