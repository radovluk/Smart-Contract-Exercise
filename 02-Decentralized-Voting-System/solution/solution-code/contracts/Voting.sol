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
    mapping(address => bool) public hasVoted;

    /**
     * @dev Event emitted when a vote is cast.
     * @param voter The address of the voter.
     * @param candidateIndex The index of the candidate voted for.
     */
    event Voted(address indexed voter, uint indexed candidateIndex);

    /**
     * @dev Event emitted when a new candidate is added.
     * @param name The name of the candidate added.
     * @param index The index of the newly added candidate.
     */
    event CandidateAdded(string name, uint index);

    /**
     * @dev Custom errors that describe the failures
     * The triple-slash comments are for natspec comments.
     * They will be shown when a user is asked to confirm a
     * transaction or when an error is thrown.
     */
    /// Only the owner can call this function.
    error NotOwner();
    /// The candidate name cannot be empty.
    error EmptyCandidateName();
    /// The `voter` has already voted.
    error AlreadyVoted(address voter);
    /// The candidate index `index` is invalid.
    error InvalidCandidateIndex(uint index);
    /// No candidates have been added yet.
    error NoCandidates();

    /**
     * @dev Modifier to restrict function access to only the contract owner.
     *      Reverts with "Not the contract owner" if the caller is not the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @dev The constructor sets the deployer as the owner.
     */
    constructor() {
        owner = msg.sender; // The deployer is the owner
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
        // Check if the candidate name is empty
        if (bytes(name).length == 0) revert EmptyCandidateName();
        // Create a new Candidate struct and push it to the candidates array
        candidates.push(Candidate({name: name, voteCount: 0}));
        // Emit the CandidateAdded event
        emit CandidateAdded(name, candidates.length - 1);
    }

    /**
     * @dev Allows a user to vote for a candidate by their index.
     * @param candidateIndex The index of the candidate in the candidates array.
     *
     * Requirements:
     * - The caller has not voted before.
     * - The candidate index is valid (within the array bounds).
     */
    function vote(uint candidateIndex) external {
        // Ensure the caller hasn't voted yet
        if (hasVoted[msg.sender]) revert AlreadyVoted(msg.sender);
        // Ensure the candidate index is valid
        if (candidateIndex >= candidates.length)
            revert InvalidCandidateIndex(candidateIndex);

        // Increment the vote count for the chosen candidate
        candidates[candidateIndex].voteCount += 1;
        // Mark the caller as having voted
        hasVoted[msg.sender] = true;

        // Emit the Voted event
        emit Voted(msg.sender, candidateIndex);
    }

    /**
     * @dev Returns the total number of candidates.
     * @return The length of the candidates array.
     */
    function getCandidateCount() external view returns (uint) {
        return candidates.length;
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
        uint index
    ) external view returns (string memory name, uint voteCount) {
        // Ensure the index is valid
        if (index >= candidates.length) revert InvalidCandidateIndex(index);
        // Retrieve the candidate from the array
        Candidate storage candidate = candidates[index];
        return (candidate.name, candidate.voteCount);
    }

    /**
     * @dev Determines the index of the candidate with the highest vote count.
     *      If multiple candidates have the same highest vote count, the first one encountered is returned.
     * @return The index of the winning candidate in the candidates array.
     *
     * Requirements:
     * - There must be at least one candidate in the array.
     */
    function winningCandidate() external view returns (uint) {
        // Revert of no candidates are added
        if (candidates.length == 0) revert NoCandidates();

        uint winningVoteCount = candidates[0].voteCount;
        uint winnerIndex = 0;
        uint candidatesLength = candidates.length; // Cache the length

        // Iterate through all candidates to find the one with the highest vote count
        for (uint i = 1; i < candidatesLength; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winnerIndex = i;
            }
        }
        return winnerIndex; // Return the index of the winning candidate
    }
}
