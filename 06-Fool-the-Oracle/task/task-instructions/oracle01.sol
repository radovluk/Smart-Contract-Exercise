// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleSynchronousOracle {
    // Stored ETH/USDC price
    int256 public price;
    // Oracle controller service address
    address public oracleService;
    
    modifier onlyController() {
        require(msg.sender == oracleService, "Not the oracle service");
        _;
    }
    constructor() {
        oracleService = msg.sender;
    }
    // Controller should periodically update the price
    function updatePrice(int256 _price) public onlyController {
        price = _price;
    }
    // Returns the latest price
    function getLatestPrice() public view returns (int256) {
        return price;
    }
}
