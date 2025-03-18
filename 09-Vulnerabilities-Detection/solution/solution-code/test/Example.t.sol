// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import "../src/Example.sol";

import {StdInvariant} from "forge-std/StdInvariant.sol";

contract ExampleTest is StdInvariant, Test {
    Example exampleContract;
    
    function setUp() public {
        exampleContract = new Example();
        targetContract(address(exampleContract));
    }
    
    function testFuzz_ShouldAlwaysBeZero() public view {
        assert(exampleContract.shouldAlwaysBeZero() == 0);
    }
}