// File: script/DeployGreeter.s.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
// Import the contract to deploy
import {Greeter} from "../src/Greeter.sol";
// Import Forge's Script utilities
import {Script} from "forge-std/Script.sol";

// Script contract that inherits from Forge's Script
contract DeployGreeter is Script {
    function run() public returns (Greeter) {
        // Start recording transactions for deployment
        vm.startBroadcast();
        // Deploy the Greeter contract with initial message
        Greeter greeter = new Greeter("Hello, Blockchain World!");
        // Stop recording transactions
        vm.stopBroadcast();
        // Return the deployed contract
        return greeter;
    }
}
