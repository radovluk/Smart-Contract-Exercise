// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {PiggyBank} from "../src/PiggyBank.sol";

/**
 * @title PiggyBankUnitTest
 * @notice Test suite for the PiggyBank contract
 * @dev This contract tests all core functionality of the PiggyBank including:
 *      - Deposits from various users
 *      - Withdrawals by the owner
 *      - Access control (only owner can withdraw)
 *      - Balance tracking
 *
 *      The tests use a standard setup with three users:
 *      - Owner: The initial deployer who has withdraw rights
 *      - Alice: Regular user who can make deposits
 *      - Bob: Another regular user who can make deposits
 */
contract PiggyBankUnitTest is Test {
    // Contract under test
    PiggyBank public piggyBank;

    // Test users
    address public owner;
    address public alice;
    address public bob;

    // Test values
    uint256 constant INITIAL_OWNER_BALANCE = 10 ether;
    uint256 constant INITIAL_USER_BALANCE = 5 ether;

    // Receive function to allow test contract to receive ETH
    receive() external payable {}

    /**
     * @notice Sets up the test environment before each test
     * This function:
     *  - Creates test accounts (owner, alice, bob)
     *  - Distributes ETH to test users
     *  - Deploys the PiggyBank contract
     */
    function setUp() public {
        // Setup accounts
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Give each user some ETH
        vm.deal(owner, INITIAL_OWNER_BALANCE);
        vm.deal(alice, INITIAL_USER_BALANCE);
        vm.deal(bob, INITIAL_USER_BALANCE);

        // Deploy PiggyBank as owner
        vm.prank(owner);
        piggyBank = new PiggyBank();
    }

    // ------------------------------------------------------------------------
    //                          Deposit Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests a single deposit from Alice
     * @dev Verifies:
     *  - The deposit increases totalDeposits correctly
     *  - The contract's ETH balance reflects the deposit
     */
    function test_SingleDeposit() public {
        uint256 depositAmount = 1 ether;

        // Alice makes a deposit
        vm.prank(alice);
        piggyBank.deposit{value: depositAmount}();

        // Check totalDeposits
        assertEq(
            piggyBank.totalDeposits(),
            depositAmount,
            "totalDeposits should match deposit amount"
        );

        // Check contract balance
        assertEq(
            address(piggyBank).balance,
            depositAmount,
            "Contract balance should match deposit amount"
        );
    }

    /**
     * @notice Tests multiple deposits from different users
     * @dev Verifies:
     *  - Total deposits accumulate correctly
     *  - Contract balance reflects all deposits
     */
    function test_MultipleDeposits() public {
        uint256 aliceDeposit = 1 ether;
        uint256 bobDeposit = 2 ether;
        uint256 ownerDeposit = 0.5 ether;

        // Alice makes a deposit
        vm.prank(alice);
        piggyBank.deposit{value: aliceDeposit}();

        // Bob makes a deposit
        vm.prank(bob);
        piggyBank.deposit{value: bobDeposit}();

        // Owner makes a deposit
        vm.prank(owner);
        piggyBank.deposit{value: ownerDeposit}();

        // Calculate total expected deposit
        uint256 totalExpectedDeposit = aliceDeposit + bobDeposit + ownerDeposit;

        // Check totalDeposits
        assertEq(
            piggyBank.totalDeposits(),
            totalExpectedDeposit,
            "totalDeposits should match sum of all deposits"
        );

        // Check contract balance
        assertEq(
            address(piggyBank).balance,
            totalExpectedDeposit,
            "Contract balance should match sum of all deposits"
        );
    }

    // ------------------------------------------------------------------------
    //                          Withdrawal Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests a withdrawal by the owner
     * @dev Verifies:
     *  - The owner can withdraw ETH
     *  - totalWithdrawals is updated correctly
     *  - Contract balance decreases appropriately
     *  - Owner's ETH balance increases by the withdrawn amount
     */
    function test_OwnerWithdrawal() public {
        // First make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: 3 ether}();

        // Record owner's balance before withdrawal
        uint256 ownerBalanceBefore = owner.balance;

        // Owner withdraws ETH
        uint256 withdrawAmount = 1 ether;
        vm.prank(owner);
        piggyBank.withdraw(withdrawAmount);

        // Check totalWithdrawals
        assertEq(
            piggyBank.totalWithdrawals(),
            withdrawAmount,
            "totalWithdrawals should match withdrawal amount"
        );

        // Check contract balance
        assertEq(
            address(piggyBank).balance,
            3 ether - withdrawAmount,
            "Contract balance should be reduced by withdrawal amount"
        );

        // Check owner's balance
        assertEq(
            owner.balance,
            ownerBalanceBefore + withdrawAmount,
            "Owner's balance should increase by withdrawal amount"
        );
    }

    /**
     * @notice Tests multiple withdrawals by the owner
     * @dev Verifies:
     *  - Owner can make multiple withdrawals
     *  - Accounting is correct across multiple operations
     */
    function test_MultipleWithdrawals() public {
        // First make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: 5 ether}();

        // Record owner's balance before withdrawals
        uint256 ownerBalanceBefore = owner.balance;

        // Owner makes first withdrawal
        uint256 firstWithdrawal = 1 ether;
        vm.prank(owner);
        piggyBank.withdraw(firstWithdrawal);

        // Owner makes second withdrawal
        uint256 secondWithdrawal = 2 ether;
        vm.prank(owner);
        piggyBank.withdraw(secondWithdrawal);

        // Calculate total withdrawal
        uint256 totalWithdrawal = firstWithdrawal + secondWithdrawal;

        // Check totalWithdrawals
        assertEq(
            piggyBank.totalWithdrawals(),
            totalWithdrawal,
            "totalWithdrawals should match sum of all withdrawals"
        );

        // Check contract balance
        assertEq(
            address(piggyBank).balance,
            5 ether - totalWithdrawal,
            "Contract balance should be reduced by total withdrawals"
        );

        // Check owner's balance
        assertEq(
            owner.balance,
            ownerBalanceBefore + totalWithdrawal,
            "Owner's balance should increase by total withdrawals"
        );
    }

    /**
     * @notice Tests complete withdrawal of all funds
     * @dev Verifies contract can be emptied completely
     */
    function test_CompleteWithdrawal() public {
        // First make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: 2 ether}();

        // Owner withdraws all ETH
        vm.prank(owner);
        piggyBank.withdraw(2 ether);

        // Check contract balance is zero
        assertEq(
            address(piggyBank).balance,
            0,
            "Contract balance should be zero after complete withdrawal"
        );

        // Check totalWithdrawals equals totalDeposits
        assertEq(
            piggyBank.totalWithdrawals(),
            piggyBank.totalDeposits(),
            "Total withdrawals should equal total deposits"
        );
    }

    // ------------------------------------------------------------------------
    //                          Error Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests that non-owner cannot withdraw
     * @dev Verifies access control is enforced
     */
    function test_RevertWhen_NonOwnerWithdraws() public {
        // First make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: 3 ether}();

        // Alice tries to withdraw (should fail)
        vm.prank(alice);
        vm.expectRevert("Only owner can withdraw");
        piggyBank.withdraw(1 ether);

        // Bob tries to withdraw (should fail)
        vm.prank(bob);
        vm.expectRevert("Only owner can withdraw");
        piggyBank.withdraw(1 ether);
    }

    /**
     * @notice Tests that withdrawal fails if amount exceeds balance
     * @dev Verifies balance check is enforced
     */
    function test_RevertWhen_WithdrawExceedsBalance() public {
        // First make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: 1 ether}();

        // Owner tries to withdraw more than available (should fail)
        vm.prank(owner);
        vm.expectRevert("Not enough funds");
        piggyBank.withdraw(2 ether);
    }

    // ------------------------------------------------------------------------
    //                          Integration Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests complete workflow with deposits and withdrawals
     * @dev Verifies everything works together in a sequence
     */
    function test_CompleteWorkflow() public {
        // Alice makes a deposit
        vm.prank(alice);
        piggyBank.deposit{value: 2 ether}();

        // Bob makes a deposit
        vm.prank(bob);
        piggyBank.deposit{value: 3 ether}();

        // Owner withdraws part of the funds
        vm.prank(owner);
        piggyBank.withdraw(1 ether);

        // Alice makes another deposit
        vm.prank(alice);
        piggyBank.deposit{value: 1 ether}();

        // Owner withdraws the rest
        vm.prank(owner);
        piggyBank.withdraw(5 ether);

        // Verify final state
        assertEq(
            piggyBank.totalDeposits(),
            6 ether,
            "Total deposits should be 6 ether"
        );
        assertEq(
            piggyBank.totalWithdrawals(),
            6 ether,
            "Total withdrawals should be 6 ether"
        );
        assertEq(
            address(piggyBank).balance,
            0,
            "Contract balance should be zero"
        );
    }
}
