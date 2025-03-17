// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Script.sol";
import "../src/Voting.sol";

/**
 * @title DeployVoting
 * @dev Deployment script for the Voting contract.
 *
 * This script deploys the Voting contract and logs its address.
 * To deploy:
 * forge script script/Deploy.s.sol:DeployVoting --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
 */
contract DeployVoting is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the Voting contract
        Voting voting = new Voting();

        // Log the deployment address (visible in forge script output)
        console.log("Voting contract deployed to:", address(voting));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
