// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleAsynchronousOracle {
    // Stored ETH/USDC price
    int256 public price;
    // Oracle controller service address
    address public oracleService;
    
    // Mapping to keep track of pending price requests
    mapping(uint256 => bool) public pendingRequests;
    uint256 public requestCount;
    
    // Only allow the oracle controller to execute certain functions
    modifier onlyController() {
        require(msg.sender == oracleService, "Not the oracle service");
        _;
    }
    
    // Constructor: the deployer becomes the oracle service
    constructor() {
        oracleService = msg.sender;
    }
    
    // User requests a price update.
    // In a real scenario, the off-chain oracle listens for this event and responds.
    function requestPriceUpdate() public returns (uint256 requestId) {
        requestCount++;
        requestId = requestCount;
        pendingRequests[requestId] = true;
        emit PriceRequested(requestId, msg.sender);
    }
    
    // The oracle controller fulfills the request with the updated price.
    // Only the designated controller can call this function.
    function fulfillPrice(uint256 requestId, int256 _price) public onlyController {
        require(pendingRequests[requestId], "Request not pending");
        pendingRequests[requestId] = false;
        price = _price;
        emit PriceUpdated(requestId, _price);
    }
    
    // Returns the latest stored price
    function getLatestPrice() public view returns (int256) {
        return price;
    }
    
    event PriceRequested(uint256 indexed requestId, address indexed requester);
    event PriceUpdated(uint256 indexed requestId, int256 price);
}
