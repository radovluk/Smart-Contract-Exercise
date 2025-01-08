// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Voting
 * @dev A simple voting contract where the owner can add candidates
 *      and any address can vote exactly once for a candidate.
 * 
 * The contract must include the following functionalities:
 * 
 * - The contract owner can add candidates.
 * - Any address can vote exactly once for a candidate.
 * - The contract tracks the number of votes each candidate has received.
 * - The contract tracks whether an address has already voted.
 * - The contract provides a function to get the total number of candidates.
 * - The contract provides a function to get a candidate's name and vote count by index.
 * - The contract provides a function to get the index of the winning candidate.
 * 
 * The contract must include the following components:
 * 
 * - `owner`: The address of the contract owner.
 * - `Candidate`: A struct representing a candidate, with a name and vote count.
 * - `candidates`: A dynamic array to store all candidates.
 * - `hasVoted`: A mapping to track whether an address has already voted.
 * 
 * The contract must include the following functions:
 * 
 * - `constructor()`: Sets the deployer as the owner.
 * - `onlyOwner()`: A modifier that only allows the owner to call certain functions.
 * - `addCandidate(string memory _name)`: Adds a new candidate (only the owner can call).
 * - `vote(uint _candidateIndex)`: Votes for a candidate by index.
 * - `getCandidateCount()`: Returns the total number of candidates.
 * - `getCandidate(uint _index)`: Returns a candidate's name and vote count by index.
 * - `winningCandidate()`: Returns the index of the winning candidate (the highest vote count).
 */
contract Voting {
    // Address of the contract owner
    address public owner;

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
     * @dev The constructor should set the deployer as the owner.
     * Constructor will be called when contract is deployed.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Modifier to restrict function access to only the contract owner.
     *      Throws an error if the caller is not the owner.
     */
    modifier onlyOwner() {
        // TODO: require that msg.sender == owner
        _;
    }

    /**
     * @dev Adds a new candidate to the candidates array.
     * @param _name The name of the candidate to be added.
     *
     * Requirements:
     * - Only the contract owner can add a candidate.
     */
    function addCandidate(string memory _name) public {
        // TODO: msg.sender must be onlyOwner (use the modifier)
        // TODO: push a new candidate into the candidates array
    }

    /**
     * @dev Allows a user to vote for a candidate by their index.
     * @param _candidateIndex The index of the candidate in the candidates array.
     *
     * Requirements:
     * - The caller has not voted before.
     * - The candidate index is valid (within the array bounds).
     */
    function vote(uint _candidateIndex) public {
        // TODO: require that msg.sender hasn't voted before
        // TODO: increment the candidate's voteCount
        // TODO: set hasVoted[msg.sender] = true
    }

    /**
     * @dev Returns the total number of candidates.
     * @return The length of the candidates array.
     */
    function getCandidateCount() public view returns (uint) {
        // TODO: return length of the candidates array
    }

    /**
     * @dev Retrieves a candidate's details by their index.
     * @param _index The index of the candidate in the candidates array.
     * @return The name and vote count of the candidate.
     *
     * Requirements:
     * - The candidate index must be within bounds.
     */
    function getCandidate(uint _index) public view returns (string memory, uint) {
        // TODO: return candidate info
    }

    /**
     * @dev Determines the index of the candidate with the highest vote count.
     *      If multiple candidates have the same highest vote count, the first one encountered is returned.
     * @return The index of the winning candidate in the candidates array.
     */
    function winningCandidate() public view returns (uint) {
        // TODO: loop through candidates, find the highest voteCount
    }
}
