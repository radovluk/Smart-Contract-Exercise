// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {PiggyBank} from "../src/PiggyBank.sol";

/**
 * @title PiggyBankStatelessFuzzTest
 * @notice Stateless fuzzing test suite for the PiggyBank contract
 * @dev This contract tests the PiggyBank with randomized inputs including:
 *      - Random deposit amounts
 *      - Random withdrawal amounts
 *      - Multiple deposits from different users
 *      - Multiple withdrawals of varying sizes
 *
 *      The tests use a standard setup with three users:
 *      - Owner: The initial deployer who has withdraw rights
 *      - Alice: Regular user who can make deposits
 *      - Bob: Another regular user who can make deposits
 */
contract PiggyBankStatelessFuzzTest is Test {
    // Contract under test
    PiggyBank public piggyBank;

    // Test users
    address public owner;
    address public alice;
    address public bob;

    // Test values
    uint256 constant INITIAL_USER_BALANCE = 100 ether; // Large balance for fuzzing

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

        // Give each user a large ETH balance for fuzzing
        vm.deal(owner, INITIAL_USER_BALANCE);
        vm.deal(alice, INITIAL_USER_BALANCE);
        vm.deal(bob, INITIAL_USER_BALANCE);

        // Deploy PiggyBank as owner
        vm.prank(owner);
        piggyBank = new PiggyBank();
    }

    // ------------------------------------------------------------------------
    //                          Deposit Fuzz Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests a single deposit with randomized amount
     * @param amount Random ETH amount to deposit
     * @dev Verifies:
     *  - The deposit increases totalDeposits correctly
     *  - The contract's ETH balance reflects the deposit
     */
    function testFuzz_SingleDeposit(uint96 amount) public {
        // Bound the amount to a reasonable range (0 ETH to 99 ETH)
        uint256 depositAmount = bound(uint256(amount), 0 ether, 99 ether);

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
     * @notice Tests multiple deposits with randomized amounts
     * @param amount1 Random ETH amount for Alice to deposit
     * @param amount2 Random ETH amount for Bob to deposit
     * @param amount3 Random ETH amount for Owner to deposit
     * @dev Verifies:
     *  - Total deposits accumulate correctly
     *  - Contract balance reflects all deposits
     */
    function testFuzz_MultipleDeposits(
        uint96 amount1,
        uint96 amount2,
        uint96 amount3
    ) public {
        // Bound the amounts to reasonable ranges
        uint256 aliceDeposit = bound(uint256(amount1), 0 ether, 99 ether);
        uint256 bobDeposit = bound(uint256(amount2), 0 ether, 99 ether);
        uint256 ownerDeposit = bound(uint256(amount3), 0 ether, 99 ether);

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
    //                          Withdrawal Fuzz Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests a withdrawal with randomized deposit and withdrawal amounts
     * @param depositAmount Random ETH amount to deposit initially
     * @param withdrawFraction Random percentage of the deposit to withdraw
     * @dev Verifies:
     *  - The owner can withdraw ETH
     *  - totalWithdrawals is updated correctly
     *  - Contract balance decreases appropriately
     */
    function testFuzz_OwnerWithdrawal(
        uint96 depositAmount,
        uint8 withdrawFraction
    ) public {
        // Bound the deposit amount to a reasonable range (0 ETH to 99 ETH)
        uint256 deposit = bound(uint256(depositAmount), 0 ether, 99 ether);

        // Bound the withdrawal fraction (1% to 100%)
        uint256 fraction = bound(uint256(withdrawFraction), 1, 100);

        // First make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: deposit}();

        // Calculate withdrawal amount as a percentage of the deposit
        uint256 withdrawAmount = (deposit * fraction) / 100;

        // Ensure withdrawal amount is non-zero
        vm.assume(withdrawAmount > 0);

        // Record owner's balance before withdrawal
        uint256 ownerBalanceBefore = owner.balance;

        // Owner withdraws ETH
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
            deposit - withdrawAmount,
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
     * @notice Tests multiple withdrawals with randomized amounts
     * @param depositAmount Random ETH amount to deposit initially
     * @param fraction1 Random percentage for first withdrawal
     * @param fraction2 Random percentage for second withdrawal
     * @dev Verifies:
     *  - Owner can make multiple withdrawals
     *  - Accounting is correct across multiple operations
     */
    function testFuzz_MultipleWithdrawals(
        uint96 depositAmount,
        uint8 fraction1,
        uint8 fraction2
    ) public {
        // Bound the deposit amount to a reasonable range (0 ETH to 99 ETH)
        uint256 deposit = bound(uint256(depositAmount), 0 ether, 99 ether);

        // First make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: deposit}();

        // Bound the withdrawal fractions
        // First withdrawal can be 1-50% of deposit
        uint256 firstFraction = bound(uint256(fraction1), 1, 50);
        uint256 firstWithdrawal = (deposit * firstFraction) / 100;

        // Second withdrawal can be 1-50% of deposit
        uint256 secondFraction = bound(uint256(fraction2), 1, 50);
        uint256 secondWithdrawal = (deposit * secondFraction) / 100;

        // Ensure total withdrawal doesn't exceed deposit
        vm.assume(firstWithdrawal + secondWithdrawal <= deposit);

        // Record owner's balance before withdrawals
        uint256 ownerBalanceBefore = owner.balance;

        // Owner makes first withdrawal
        vm.prank(owner);
        piggyBank.withdraw(firstWithdrawal);

        // Owner makes second withdrawal
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
            deposit - totalWithdrawal,
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
     * @notice Tests complete withdrawal of all funds with randomized deposit amount
     * @param depositAmount Random ETH amount to deposit and then completely withdraw
     * @dev Verifies contract can be emptied completely with various deposit sizes
     */
    function testFuzz_CompleteWithdrawal(uint256 depositAmount) public {
        // Bound the deposit amount to a reasonable range (0 ETH to 99 ETH)
        uint256 deposit = bound(uint256(depositAmount), 0 ether, 99 ether);

        // Make a deposit to the piggy bank
        vm.prank(alice);
        piggyBank.deposit{value: deposit}();

        // Owner withdraws all ETH
        vm.prank(owner);
        piggyBank.withdraw(deposit);

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
    //                          Error Fuzz Tests
    // ------------------------------------------------------------------------

    /**
     * @notice Tests that non-owner withdrawals fail with different users and amounts
     * @param depositAmount Random deposit amount
     * @param withdrawAmount Random withdrawal amount
     * @param nonOwner Random non-owner address
     * @dev Verifies access control for any input
     */
    function testFuzz_NonOwnerWithdrawFails(
        uint96 depositAmount,
        uint96 withdrawAmount,
        address nonOwner
    ) public {
        // Exclude owner from test addresses
        vm.assume(nonOwner != owner);
        vm.assume(nonOwner != address(0));

        // Bound deposit amount
        uint256 deposit = bound(uint256(depositAmount), 0 ether, 99 ether);

        // First make a deposit
        vm.prank(alice);
        piggyBank.deposit{value: deposit}();

        // Bound withdrawal amount to be within deposit
        uint256 withdraw = bound(uint256(withdrawAmount), 0 ether, deposit);

        // Fund the non-owner so they can make a transaction
        vm.deal(nonOwner, 1 ether);

        // Non-owner tries to withdraw (should fail)
        vm.prank(nonOwner);
        vm.expectRevert(PiggyBank.NotOwner.selector);
        piggyBank.withdraw(withdraw);
    }

    /**
     * @notice Tests that withdrawing more than the balance fails with different amounts
     * @param depositAmount Random deposit amount
     * @param excessFactor Random factor by which to exceed the balance
     * @dev Verifies balance check for any input
     */
    function testFuzz_WithdrawExceedsBalanceFails(
        uint96 depositAmount,
        uint8 excessFactor
    ) public {
        // Bound deposit amount
        uint256 deposit = bound(uint256(depositAmount), 0.01 ether, 10 ether);

        // First make a deposit
        vm.prank(alice);
        piggyBank.deposit{value: deposit}();

        // Calculate withdrawal amount that exceeds balance
        // Excess factor determines how much to exceed by (101-200%)
        uint256 factor = bound(uint256(excessFactor), 1, 100) + 100;
        uint256 excessWithdrawal = (deposit * factor) / 100;

        // Ensure withdrawal amount actually exceeds balance
        vm.assume(excessWithdrawal > deposit);

        // Owner tries to withdraw too much (should fail)
        vm.prank(owner);
        vm.expectRevert(PiggyBank.InsufficientFunds.selector);
        piggyBank.withdraw(excessWithdrawal);
    }

    // ------------------------------------------------------------------------
    //                           Integration Fuzz Test
    // ------------------------------------------------------------------------

    /* @notice Tests complete workflow with deposits and withdrawals using randomized amounts
     * @param depositAmounts Array of random ETH amounts for deposits
     * @param withdrawFraction Random percentage for first withdrawal
     * @dev Verifies everything works together in a sequence with various amounts
     */
    function testFuzz_CompleteWorkflow(
        uint96[3] memory depositAmounts,
        uint8 withdrawFraction
    ) public {
        // Bound deposit amounts to reasonable ranges
        uint256 aliceDeposit1 = bound(
            uint256(depositAmounts[0]),
            0 ether,
            49 ether
        );
        uint256 bobDeposit = bound(
            uint256(depositAmounts[1]),
            0 ether,
            99 ether
        );
        uint256 aliceDeposit2 = bound(
            uint256(depositAmounts[2]),
            0 ether,
            49 ether
        );

        // Alice makes first deposit
        vm.prank(alice);
        piggyBank.deposit{value: aliceDeposit1}();

        // Bob makes a deposit
        vm.prank(bob);
        piggyBank.deposit{value: bobDeposit}();

        // Calculate first withdrawal amount (percentage of total deposits so far)
        uint256 totalInitialDeposits = aliceDeposit1 + bobDeposit;
        uint256 firstWithdrawPercentage = bound(
            uint256(withdrawFraction),
            5,
            50
        ); // 5-50% of deposits
        uint256 firstWithdrawal = (totalInitialDeposits *
            firstWithdrawPercentage) / 100;

        // Ensure first withdrawal is within balance and non-zero
        vm.assume(
            firstWithdrawal > 0 && firstWithdrawal < totalInitialDeposits
        );

        // Owner withdraws part of the funds
        vm.prank(owner);
        piggyBank.withdraw(firstWithdrawal);

        // Alice makes another deposit
        vm.prank(alice);
        piggyBank.deposit{value: aliceDeposit2}();

        // Total deposits across all operations
        uint256 totalDeposits = aliceDeposit1 + bobDeposit + aliceDeposit2;

        // Calculate remaining balance to withdraw
        uint256 remainingBalance = totalDeposits - firstWithdrawal;

        // Owner withdraws the rest
        vm.prank(owner);
        piggyBank.withdraw(remainingBalance);

        // Verify final state
        assertEq(
            piggyBank.totalDeposits(),
            totalDeposits,
            "Total deposits should match sum of all deposits"
        );
        assertEq(
            piggyBank.totalWithdrawals(),
            totalDeposits,
            "Total withdrawals should equal total deposits"
        );
        assertEq(
            address(piggyBank).balance,
            0,
            "Contract balance should be zero"
        );
    }
}
