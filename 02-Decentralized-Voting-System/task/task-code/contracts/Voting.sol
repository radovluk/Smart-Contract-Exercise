// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title Voting
 * @dev A simple voting contract where the owner can add candidates
 *      and any address can vote exactly once for a candidate.
 *
 * The contract includes the following functionalities:
 *
 * - The contract owner can add candidates.
 * - Any address can vote exactly once for a candidate.
 * - The contract tracks the number of votes each candidate has received.
 * - The contract tracks whether an address has already voted.
 * - The contract provides a function to get the total number of candidates.
 * - The contract provides a function to get a candidate's name and vote count by index.
 * - The contract provides a function to get the index of the winning candidate.
 */
contract Voting {
    // Address of the contract owner
    address public immutable owner;

    /**
     * @dev Struct to represent a candidate.
     * @param name The name of the candidate.
     * @param voteCount The number of votes the candidate has received.
     */
    struct Candidate {
        string name;
        uint96 voteCount;
    }

    // Dynamic array to store all candidates
    Candidate[] public candidates;

    // Mapping to track whether an address has already voted
    mapping(address voter => bool hasVoted) public hasVoted;

    /**
     * @dev Event emitted when a vote is cast.
     * @param voter The address of the voter.
     * @param candidateIndex The index of the candidate voted for.
     */
    event Voted(address indexed voter, uint256 indexed candidateIndex);

    /**
     * @dev Event emitted when a new candidate is added.
     * @param name The name of the candidate added.
     * @param index The index of the newly added candidate.
     */
    // TODO: Create an event to emit when a new candidate is added

    /**
     * @dev Custom errors for descriptive failure messages
     */
    /// Only the owner can call this function.
    error NotOwner();
    /// The candidate name cannot be empty.
    error EmptyCandidateName();
    /// The `voter` has already voted.
    error AlreadyVoted(address voter);
    /// The candidate index `index` is invalid.
    error InvalidCandidateIndex(uint256 index);
    /// No candidates have been added yet.
    error NoCandidates();

    /**
     * @dev Modifier to restrict function access to only the contract owner.
     *      Reverts with NotOwner() if the caller is not the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _; // this line represents where the modified function's code executes
    }

    /**
     * @dev The constructor sets the deployer as the owner.
     */
    constructor() {
        // TODO: Set the deployer of the contract as the owner
        // HINT: Use msg.sender to get the address of the deployer
    }

    /**
     * @dev Adds a new candidate to the candidates array.
     * @param name The name of the candidate to be added.
     *
     * Requirements:
     * - Only the contract owner can add a candidate.
     * - The candidate name cannot be empty.
     */
    function addCandidate(string calldata name) external onlyOwner {
        // TODO: Ensure that the candidate name is not empty
        // TODO: Create a new Candidate struct with the provided name and zero votes
        // TODO: Add the new candidate to the candidates array
        // TODO: Emit the CandidateAdded event with the candidate's name and index
    }

    /**
     * @dev Allows a user to vote for a candidate by their index.
     * @param candidateIndex The index of the candidate in the candidates array.
     *
     * Requirements:
     * - The caller has not voted before.
     * - The candidate index is valid (within the array bounds).
     */
    function vote(uint256 candidateIndex) external {
        // TODO: Check if the sender has already voted
        // Tip: Use msg.sender to get the sender address and custom error.
        // TODO: Check if the candidate index is within the valid range
        // TODO: Increment the vote count for the chosen candidate
        // TODO: Mark the sender as having voted
        // TODO: Emit the Voted event with the voter's address and candidate index
        //       (This will allow clients to listen for the event and react to it)
    }

    /**
     * @dev Returns the total number of candidates.
     * @return count The length of the candidates array.
     */
    function getCandidateCount() external view returns (uint256 count) {
        // TODO: Return the number of candidates in the candidates array
    }

    /**
     * @dev Retrieves a candidate's details by their index.
     * @param index The index of the candidate in the candidates array.
     * @return name The name of the candidate.
     * @return voteCount The number of votes the candidate has received.
     *
     * Requirements:
     * - The candidate index must be within bounds.
     */
    function getCandidate(
        uint256 index
    ) external view returns (string memory name, uint256 voteCount) {
        // TODO: Ensure the index is within the valid range
        // TODO: Retrieve the candidate's name and vote count from the candidates array
    }

    /**
     * @dev Determines the index of the candidate with the highest vote count.
     *      If multiple candidates have the same highest vote count, the first one encountered is returned.
     * @return winnerIndex The index of the winning candidate in the candidates array.
     *
     * Requirements:
     * - There must be at least one candidate in the array.
     */
    function winningCandidate() external view returns (uint256 winnerIndex) {
        // TODO: Ensure there is at least one candidate to determine a winner
        // TODO: Initialize variables to track the highest vote count and winner index
        // TODO: Cache the length of the candidates array before looping through it
        // TODO: Return the index of the winning candidate
    }
}
