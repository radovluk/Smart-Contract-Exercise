// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// ======== Custom Error Definitions ========
error OnlyOwner();               // Thrown when a non-owner calls an onlyOwner function
error CampaignAlreadyCanceled(); // Thrown when canceling an already-canceled campaign
error CampaignNotCanceled();     // Thrown when claimRefund is called but the campaign is not canceled
error CampaignIsCanceled();      // Thrown when donating to a canceled campaign or withdrawing after cancellation
error NoDonationToRefund();      // Thrown when a user tries to claim a refund with no donation
error TransferFailed();          // Thrown when an external call to transfer Ether fails

/**
 * @title CatCharity
 * @notice This contract collects donations to help save kittens.
 *         - Anyone can donate Ether to support the cause.
 *         - The owner can cancel the campaign at any time, allowing donors to request a refund.
 *         - The owner can also withdraw all collected funds if the campaign is still active.
 */
contract CatCharity {
    // Address of the contract owner who can cancel or withdraw funds.
    address public owner;

    // Indicates whether the campaign is canceled (true) or still active (false).
    bool public isCanceled;

    // Maps each donor's address to the total Ether amount they have donated.
    mapping(address => uint256) public donations;

    // Stores the address of the most recently refunded donor.
    address public lastRefunded;

    // ======== MODIFIERS ========

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    /**
     * @dev Sets the initial owner to the contract deployer
     *      and the campaign is active by default (isCanceled = false).
     */
    constructor() {
        owner = msg.sender;
        isCanceled = false;
    }

    /**
     * @dev Allows anyone to donate Ether to help save kittens.
     *      The donation is credited to the sender's address.
     */
    function donate() external payable {
        donations[msg.sender] += msg.value;
    }

    /**
     * @dev The owner can cancel the campaign, stopping future donations
     *      and allowing donors to claim a refund.
     *      Reverts if the campaign is already canceled.
     */
    function cancelCampaign() external onlyOwner {
        if (isCanceled) {
            revert CampaignAlreadyCanceled();
        }
        isCanceled = true;
    }

    /**
     * @dev If the campaign is canceled, donors can claim a refund of their donation.
     *      Reverts if the campaign is not canceled or if there's no donation to refund.
     */
    function claimRefund() external {
        if (!isCanceled) {
            revert CampaignNotCanceled();
        }
        uint256 donated = donations[msg.sender];
        if (donated == 0) {
            revert NoDonationToRefund();
        }
        
        (bool success, ) = payable(msg.sender).call{value: donated}("");
        if (!success) {
            revert TransferFailed();
        }

        donations[msg.sender] = 0;
        lastRefunded = msg.sender;
    }

    /**
     * @dev The owner can withdraw all Ether if the campaign is still active.
     *      Reverts if the campaign has been canceled or if there are no funds.
     */
    function ownerWithdrawAll() external onlyOwner {
        if (isCanceled) {
            revert CampaignIsCanceled();
        }
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) {
            revert TransferFailed();
        }

        (bool success, ) = payable(msg.sender).call{value: contractBalance}("");
        if (!success) {
            revert TransferFailed();
        }
    }
}
