// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {PiggyBank} from "../src/PiggyBank.sol";

/**
 * @title PiggyBankInvariantTest
 * @notice Invariant testing for the PiggyBank contract
 * @dev This test suite verifies that critical invariants of the PiggyBank
 *      contract hold true regardless of the sequence of operations performed.
 *      Key invariants tested include:
 *      - Contract balance equals totalDeposits minus totalWithdrawals
 *      - Only the owner can successfully withdraw
 *      - Total withdrawals never exceed total deposits
 */

/**
 * @title PiggyBankHandler
 * @notice Handler contract for invariant testing of the PiggyBank
 * @dev This contract provides functions that will be called randomly by the
 *      fuzzer, allowing us to test system invariants across random
 *      sequences of operations
 */
contract PiggyBankInvariantTest is Test {
    PiggyBank public piggyBank;
    PiggyBankHandler public handler;
    address public owner;

    /**
     * @notice Sets up the test environment before each invariant test run
     * This happens once at the beginning of the invariant test campaign
     */
    function setUp() public {
        // Set owner to a defined address
        owner = makeAddr("owner");
        vm.prank(owner);

        // Deploy the PiggyBank contract
        piggyBank = new PiggyBank();

        // Deploy the handler
        handler = new PiggyBankHandler(piggyBank, owner);

        // Target the handler for invariant testing
        targetContract(address(handler));
    }

    // ------------------------------------------------------------------------
    //                                 Invariants
    // ------------------------------------------------------------------------

    /**
     * @notice Invariant #1: Contract balance should always equal totalDeposits - totalWithdrawals
     * @dev This verifies the core accounting of the contract is correct
     */
    function invariant_balanceMatchesAccountingDiff() public view {
        assertEq(
            address(piggyBank).balance,
            piggyBank.totalDeposits() - piggyBank.totalWithdrawals(),
            "Contract balance should equal totalDeposits - totalWithdrawals"
        );
    }

    /**
     * @notice Invariant #2: Total withdrawals should never exceed total deposits
     * @dev This verifies you can't withdraw more than was deposited
     */
    function invariant_withdrawalsLessThanDeposits() public view {
        assertLe(
            piggyBank.totalWithdrawals(),
            piggyBank.totalDeposits(),
            "Total withdrawals should never exceed total deposits"
        );
    }

    /**
     * @notice Invariant #3: Handler's tracked deposits should match contract's totalDeposits
     * @dev This ensures the internal state tracking is accurate
     */
    function invariant_handlerTrackedDeposits() public view {
        assertEq(
            handler.totalDeposited(),
            piggyBank.totalDeposits(),
            "Handler's tracked deposits should match contract's totalDeposits"
        );
    }

    /**
     * @notice Invariant #4: Handler's tracked withdrawals should match contract's totalWithdrawals
     * @dev This ensures the internal state tracking is accurate
     */
    function invariant_handlerTrackedWithdrawals() public view {
        assertEq(
            handler.totalWithdrawn(),
            piggyBank.totalWithdrawals(),
            "Handler's tracked withdrawals should match contract's totalWithdrawals"
        );
    }
}

// ------------------------------------------------------------------------
//                           Handler Contract
// ------------------------------------------------------------------------

contract PiggyBankHandler is Test {
    PiggyBank public piggyBank;
    address public owner;

    // Track actors who can interact with the contract
    address[] public actors;
    mapping(address => bool) public isActor;

    // Track total ETH deposited and withdrawn for invariant verification
    uint256 public totalDeposited;
    uint256 public totalWithdrawn;

    /**
     * @notice Constructor for the handler
     * @param _piggyBank The deployed PiggyBank contract to test
     * @param _owner The owner of the PiggyBank
     */
    constructor(PiggyBank _piggyBank, address _owner) {
        piggyBank = _piggyBank;
        owner = _owner;

        // Initialize actors
        actors.push(address(0x1)); // Alice
        actors.push(address(0x2)); // Bob
        actors.push(address(0x3)); // Charlie
        actors.push(address(0x4)); // Dave
        actors.push(address(0x5)); // Eve
        actors.push(_owner); // Owner

        // Register actors in the mapping for quick lookup
        for (uint256 i = 0; i < actors.length; i++) {
            isActor[actors[i]] = true;
        }

        // Fund all actors
        for (uint256 i = 0; i < actors.length; i++) {
            vm.deal(actors[i], 100 ether);
        }
    }

    /**
     * @notice Handler function: deposit ETH into the PiggyBank
     * @param actorIdx Random number used to select which actor performs the deposit
     * @param amount Random amount of ETH to deposit
     */
    function deposit(uint256 actorIdx, uint256 amount) external {
        // Select an actor to perform the deposit
        address actor = getActor(actorIdx);
        amount = bound(amount, 0 ether, actor.balance / 2);

        // Make the deposit
        vm.prank(actor);
        piggyBank.deposit{value: amount}();

        // Track total deposits for invariant checking
        totalDeposited += amount;
    }

    /**
     * @notice Handler function: withdraw ETH from the PiggyBank
     * @param amount Random amount of ETH to withdraw
     */
    function withdraw(uint256 amount) external {
        // Bound amount to something within the current balance
        amount = bound(amount, 0, address(piggyBank).balance);

        // Make the withdrawal as owner
        vm.prank(owner);
        piggyBank.withdraw(amount);

        // Track total withdrawals for invariant checking
        totalWithdrawn += amount;
    }

    /**
     * @notice Handler function: attempt to withdraw as non-owner (should fail)
     * @param actorIdx Random number used to select which non-owner actor attempts the withdrawal
     * @param amount Random amount of ETH to attempt to withdraw
     */
    function withdrawAsNonOwner(uint256 actorIdx, uint256 amount) external {
        // Select a non-owner actor to perform the withdrawal attempt
        address actor = getNonOwner(actorIdx);

        // Bound amount to something within the current balance
        amount = bound(amount, 0 ether, address(piggyBank).balance);

        // Attempt to withdraw as non-owner (should fail)
        vm.prank(actor);

        // We expect this to revert, but we don't want to fail the handler call
        try piggyBank.withdraw(amount) {
            // This should never succeed - if it does, we have a serious issue!
            assert(false);
        } catch {
            // Expected to fail - this is correct behavior
        }
    }

    // ------------------------------------------------------------------------
    //                          Helper Functions
    // ------------------------------------------------------------------------

    /**
     * @notice Helper function to select a random actor from our actor list
     * @param actorIdxSeed A random number seed used to select an actor
     * @return The selected actor's address
     */
    function getActor(uint256 actorIdxSeed) internal view returns (address) {
        return actors[bound(actorIdxSeed, 0, actors.length - 1)];
    }

    /**
     * @notice Helper function to select a random non-owner actor from our actor list
     * @param actorIdxSeed A random number seed used to select a non-owner actor
     * @return The selected non-owner actor's address
     */
    function getNonOwner(uint256 actorIdxSeed) internal view returns (address) {
        // Select an actor that is not the owner
        address actor;
        uint256 idx = bound(actorIdxSeed, 0, actors.length - 2); // -2 because we have owner as the last actor

        // If the selected index would give us the owner, return the last actor instead
        if (actors[idx] == owner) {
            actor = actors[actors.length - 2]; // Second-to-last actor
        } else {
            actor = actors[idx];
        }

        return actor;
    }
}
