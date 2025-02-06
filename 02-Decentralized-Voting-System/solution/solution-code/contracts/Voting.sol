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
        uint voteCount;
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
     * @param name The name of the candidate to be added.
     */
    event CandidateAdded(string name);

    /**
     * @dev The constructor sets the deployer as the owner.
     */
    constructor() {
        owner = msg.sender; // The deployer is the owner
    }

    /**
     * @dev Modifier to restrict function access to only the contract owner.
     *      Reverts with "Not the contract owner" if the caller is not the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    /**
     * @dev Adds a new candidate to the candidates array.
     * @param name The name of the candidate to be added.
     *
     * Requirements:
     * - Only the contract owner can add a candidate.
     * - The candidate name cannot be empty.
     */
    function addCandidate(string memory name) public onlyOwner {
        require(bytes(name).length > 0, "Candidate name cannot be empty");
        // Create a new Candidate struct and push it to the candidates array
        candidates.push(Candidate({name: name, voteCount: 0}));
        // Emit the CandidateAdded event
        emit CandidateAdded(name);
    }

    /**
     * @dev Allows a user to vote for a candidate by their index.
     * @param candidateIndex The index of the candidate in the candidates array.
     *
     * Requirements:
     * - The caller has not voted before.
     * - The candidate index is valid (within the array bounds).
     */
    function vote(uint candidateIndex) public {
        // Ensure the caller hasn't voted yet
        require(!hasVoted[msg.sender], "Already voted");
        // Ensure the candidate index is valid
        require(candidateIndex < candidates.length, "Invalid candidate index");

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
    function getCandidateCount() public view returns (uint) {
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
    function getCandidate(uint index) public view returns (string memory name, uint voteCount) {
        // Ensure the index is valid
        require(index < candidates.length, "Index out of range");
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
    function winningCandidate() public view returns (uint) {
        require(candidates.length > 0, "No candidates available");

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

