// File: test/Greeter.t.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
// Import the contract to test
import {Greeter} from "../src/Greeter.sol";
// Import Forge's testing utilities
import {Test} from "forge-std/Test.sol";

// Test contract that inherits from Test
contract GreeterTest is Test {
    // Instance of the contract to test
    Greeter greeter;
    // The initial greeting for testing
    string constant INITIAL_GREETING = "Hello, Blockchain World!";

    // Set up function that runs before each test
    function setUp() public {
        greeter = new Greeter(INITIAL_GREETING);
    }

    // Test to ensure the initial greeting is set correctly
    function test_InitialGreeting() public view {
        string memory greeting = greeter.greet();
        assertEq(greeting, INITIAL_GREETING);
    }
}
