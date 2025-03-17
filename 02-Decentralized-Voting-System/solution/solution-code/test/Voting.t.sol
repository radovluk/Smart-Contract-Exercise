// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import "forge-std/Test.sol";
import "../src/Voting.sol";

/**
 * @title VotingTest
 * @dev Test contract for the Voting contract.
 */
contract VotingTest is Test {
    Voting voting;
    address owner;
    address voter1;
    address voter2;
    address voter3;
    address voter4;
    address voter5;
    address nonOwner;

    // Set up the test environment before each test
    function setUp() public {
        // Create test addresses
        owner = makeAddr("owner");
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");
        voter4 = makeAddr("voter4");
        voter5 = makeAddr("voter5");
        nonOwner = makeAddr("nonOwner");

        // Deploy the contract as the owner
        vm.prank(owner);
        voting = new Voting();
    }

    // ======== Deployment Tests ========

    function testDeployment() public view {
        // Test contract address is valid
        assertTrue(address(voting) != address(0));

        // Test owner is set correctly
        assertEq(voting.owner(), owner);

        // Test initial candidate count is zero
        assertEq(voting.getCandidateCount(), 0);
    }

    // ======== Access Control Tests ========

    function testOwnerCanAddCandidates() public {
        // Owner adds a candidate
        vm.prank(owner);
        voting.addCandidate("Alice");

        // Check candidate was added
        assertEq(voting.getCandidateCount(), 1);
    }

    function testNonOwnerCannotAddCandidates() public {
        // Non-owner attempts to add a candidate
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Voting.NotOwner.selector));
        voting.addCandidate("Bob");
    }

    // ======== Candidates Management Tests ========

    function testAddMultipleCandidates() public {
        // Owner adds multiple candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        vm.stopPrank();

        // Check candidates were added
        assertEq(voting.getCandidateCount(), 3);

        // Check first candidate details
        (string memory name1, uint voteCount1) = voting.getCandidate(0);
        assertEq(name1, "Alice");
        assertEq(voteCount1, 0);

        // Check second candidate details
        (string memory name2, uint voteCount2) = voting.getCandidate(1);
        assertEq(name2, "Bob");
        assertEq(voteCount2, 0);

        // Check third candidate details
        (string memory name3, uint voteCount3) = voting.getCandidate(2);
        assertEq(name3, "Charlie");
        assertEq(voteCount3, 0);
    }

    function testCannotAddEmptyCandidateName() public {
        // Owner tries to add candidate with empty name
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(Voting.EmptyCandidateName.selector)
        );
        voting.addCandidate("");
    }

    function testAllowDuplicateCandidateNames() public {
        // Add the same name twice
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Alice");
        vm.stopPrank();

        // Check both candidates were added
        assertEq(voting.getCandidateCount(), 2);

        // Check they have the same name
        (string memory name1, ) = voting.getCandidate(0);
        (string memory name2, ) = voting.getCandidate(1);
        assertEq(name1, "Alice");
        assertEq(name2, "Alice");
    }

    function testCandidateAddedEvent() public {
        // Check that the event is emitted with correct parameters
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit Voting.CandidateAdded("Alice", 0);
        voting.addCandidate("Alice");
    }

    // ======== Voting Mechanism Tests ========

    function testVoteForCandidate() public {
        // Add a candidate
        vm.prank(owner);
        voting.addCandidate("Alice");

        // Cast a vote
        vm.prank(voter1);
        vm.expectEmit(true, true, true, true);
        emit Voting.Voted(voter1, 0);
        voting.vote(0);

        // Check vote was counted
        (, uint voteCount) = voting.getCandidate(0);
        assertEq(voteCount, 1);

        // Check voter is marked as having voted
        assertTrue(voting.hasVoted(voter1));
    }

    function testCannotVoteForNonExistentCandidate() public {
        // Try to vote without any candidates
        vm.prank(voter1);
        vm.expectRevert(
            abi.encodeWithSelector(Voting.InvalidCandidateIndex.selector, 0)
        );
        voting.vote(0);
    }

    function testCannotVoteMoreThanOnce() public {
        // Add a candidate
        vm.prank(owner);
        voting.addCandidate("Alice");

        // Vote once
        vm.prank(voter1);
        voting.vote(0);

        // Try to vote again
        vm.prank(voter1);
        vm.expectRevert(
            abi.encodeWithSelector(Voting.AlreadyVoted.selector, voter1)
        );
        voting.vote(0);
    }

    function testMultipleVotersForDifferentCandidates() public {
        // Add two candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        vm.stopPrank();

        // Two voters vote for different candidates
        vm.prank(voter1);
        voting.vote(0); // Voter1 votes for Alice

        vm.prank(voter2);
        voting.vote(1); // Voter2 votes for Bob

        // Check vote counts
        (, uint aliceVotes) = voting.getCandidate(0);
        (, uint bobVotes) = voting.getCandidate(1);

        assertEq(aliceVotes, 1);
        assertEq(bobVotes, 1);
    }

    // ======== Results and Winner Tests ========

    function testCorrectVoteCounts() public {
        // Add two candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        vm.stopPrank();

        // Cast votes
        vm.prank(voter1);
        voting.vote(0); // Alice: 1

        vm.prank(voter2);
        voting.vote(1); // Bob: 1

        vm.prank(voter3);
        voting.vote(1); // Bob: 2

        // Check vote counts
        (, uint aliceVotes) = voting.getCandidate(0);
        (, uint bobVotes) = voting.getCandidate(1);

        assertEq(aliceVotes, 1);
        assertEq(bobVotes, 2);
    }

    function testWinningCandidate() public {
        // Add two candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        vm.stopPrank();

        // Both voters vote for Bob
        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(1);

        // Bob should be the winner
        uint winnerIndex = voting.winningCandidate();
        assertEq(winnerIndex, 1);
    }

    function testMultipleCandidatesWinner() public {
        // Add three candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        vm.stopPrank();

        // Cast votes
        vm.prank(voter1);
        voting.vote(0); // Alice: 1

        vm.prank(voter2);
        voting.vote(1); // Bob: 1

        vm.prank(voter3);
        voting.vote(1); // Bob: 2

        vm.prank(voter4);
        voting.vote(2); // Charlie: 1

        // Bob should be the winner
        uint winnerIndex = voting.winningCandidate();
        assertEq(winnerIndex, 1);
    }

    // ======== Getter Functions Tests ========

    function testGetCandidate() public {
        // Add a candidate
        vm.prank(owner);
        voting.addCandidate("Alice");

        // Get candidate details
        (string memory name, uint voteCount) = voting.getCandidate(0);
        assertEq(name, "Alice");
        assertEq(voteCount, 0);
    }

    function testInvalidCandidateIndex() public {
        // Try to get non-existent candidate
        vm.expectRevert(
            abi.encodeWithSelector(Voting.InvalidCandidateIndex.selector, 0)
        );
        voting.getCandidate(0);
    }

    function testGetCandidateCount() public {
        // Check initial count
        assertEq(voting.getCandidateCount(), 0);

        // Add candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        vm.stopPrank();

        // Check updated count
        assertEq(voting.getCandidateCount(), 2);
    }

    // ======== Edge Cases Tests ========

    function testVotingWithNoCandidates() public {
        // Try to vote without candidates
        vm.prank(voter1);
        vm.expectRevert(
            abi.encodeWithSelector(Voting.InvalidCandidateIndex.selector, 0)
        );
        voting.vote(0);
    }

    function testNoWinnerWithoutCandidates() public {
        // Try to get winner without candidates
        vm.expectRevert(abi.encodeWithSelector(Voting.NoCandidates.selector));
        voting.winningCandidate();
    }

    function testMultipleVotesAccurateTracking() public {
        // Add three candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        vm.stopPrank();

        // Cast multiple votes
        vm.prank(voter1);
        voting.vote(0); // Alice: 1

        vm.prank(voter2);
        voting.vote(1); // Bob: 1

        vm.prank(voter3);
        voting.vote(1); // Bob: 2

        vm.prank(voter4);
        voting.vote(2); // Charlie: 1

        vm.prank(voter5);
        voting.vote(1); // Bob: 3

        // Check vote counts
        (, uint aliceVotes) = voting.getCandidate(0);
        (, uint bobVotes) = voting.getCandidate(1);
        (, uint charlieVotes) = voting.getCandidate(2);

        assertEq(aliceVotes, 1);
        assertEq(bobVotes, 3);
        assertEq(charlieVotes, 1);

        // Check winner
        uint winnerIndex = voting.winningCandidate();
        assertEq(winnerIndex, 1); // Bob should be the winner
    }

    function testNoMultipleVotesAcrossCandidates() public {
        // Add two candidates
        vm.startPrank(owner);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        vm.stopPrank();

        // Vote for Alice
        vm.prank(voter1);
        voting.vote(0);

        // Try to vote for Bob with the same address
        vm.prank(voter1);
        vm.expectRevert(
            abi.encodeWithSelector(Voting.AlreadyVoted.selector, voter1)
        );
        voting.vote(1);
    }
}
