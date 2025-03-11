// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

/**
 * @title DAO
 * @notice A simple decentralized autonomous organization (DAO) contract
 *         that demonstrates a vulnerability to a DoS attack.
 *         - Members can join the DAO by paying a membership fee
 *         - Members can vote on proposals
 *         - When a proposal gets a majority vote, it passes
 *         - Passed proposals can be executed after the voting period
 *         - The DAO can execute proposals to transfer funds or call external contracts
 */
contract DAO {
    // ------------------------------------------------------------------------
    //                          Storage Variables
    // ------------------------------------------------------------------------

    // DAO configuration
    uint256 public constant MEMBERSHIP_FEE = 1 ether;
    uint256 public constant VOTING_PERIOD = 1 days;

    // Membership tracking
    mapping(address => bool) public isMember;
    uint256 public memberCount;

    // Proposal state
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address target;
        uint256 value;
        bytes data;
        uint256 createdAt;
        uint256 voteCount;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Treasury funds that can be allocated via proposals
    uint256 public treasuryBalance;

    // The address that deployed the contract
    address public immutable founder;

    // ------------------------------------------------------------------------
    //                               Events
    // ------------------------------------------------------------------------

    /// Emitted when a new member joins the DAO
    event MemberJoined(address indexed member);

    /// Emitted when a new proposal is created
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description
    );

    /// Emitted when a member votes on a proposal
    event Voted(uint256 indexed proposalId, address indexed voter);

    /// Emitted when a proposal is executed
    event ProposalExecuted(uint256 indexed proposalId);

    /// Emitted when funds are received by the DAO
    event FundsReceived(address indexed from, uint256 amount);

    // ------------------------------------------------------------------------
    //                               Errors
    // ------------------------------------------------------------------------

    /// The sender is already a member of the DAO
    error AlreadyMember();

    /// The sender hasn't provided enough funds
    error InsufficientFunds();

    /// The sender is not a member of the DAO
    error NotMember();

    /// The specified proposal doesn't exist
    error ProposalDoesNotExist();

    /// The sender has already voted on this proposal
    error AlreadyVoted();

    /// The voting period for this proposal has ended
    error VotingPeriodEnded();

    /// The voting period for this proposal has not ended yet
    error VotingPeriodNotEnded();

    /// The proposal has already been executed
    error ProposalAlreadyExecuted();

    /// The proposal execution failed
    error ProposalExecutionFailed();

    /// The proposal hasn't received enough votes to pass
    error ProposalNotPassed();

    /// No proposals have passed and are ready to be executed
    error NoPassedProposals();

    // ------------------------------------------------------------------------
    //                               Modifiers
    // ------------------------------------------------------------------------

    /**
     * @dev Modifier to restrict function access to only DAO members.
     */
    modifier onlyMember() {
        if (!isMember[msg.sender]) {
            revert NotMember();
        }
        _;
    }

    // ------------------------------------------------------------------------
    //                               Constructor
    // ------------------------------------------------------------------------

    /**
     * @dev Constructor for initializing the DAO
     */
    constructor() payable {
        founder = msg.sender;

        // If the contract is deployed with ETH, add it to the treasury
        if (msg.value > 0) {
            treasuryBalance += msg.value;
            emit FundsReceived(msg.sender, msg.value);
        }
    }

    // ------------------------------------------------------------------------
    //                          Contract Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows anyone to become a member by paying the membership fee
     */
    function joinDAO() external payable {
        if (isMember[msg.sender]) {
            revert AlreadyMember();
        }
        if (msg.value < MEMBERSHIP_FEE) {
            revert InsufficientFunds();
        }

        isMember[msg.sender] = true;
        memberCount++;

        // Add the membership fee to treasury
        treasuryBalance += msg.value;

        emit MemberJoined(msg.sender);
    }

    /**
     * @dev Allows members to create a proposal
     * @param description Brief description of the proposal
     * @param target The address that will be called if the proposal passes
     * @param value The amount of ETH to send with the call
     * @param data The calldata to send with the call
     */
    function createProposal(
        string memory description,
        address target,
        uint256 value,
        bytes memory data
    ) external onlyMember {
        // Create the proposal
        uint256 proposalId = proposals.length;
        proposals.push(
            Proposal({
                id: proposalId,
                proposer: msg.sender,
                description: description,
                target: target,
                value: value,
                data: data,
                createdAt: block.timestamp,
                voteCount: 0,
                executed: false
            })
        );

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @dev Allows members to vote on a proposal
     * @param proposalId The ID of the proposal to vote on
     */
    function vote(uint256 proposalId) external onlyMember {
        if (proposalId >= proposals.length) {
            revert ProposalDoesNotExist();
        }

        Proposal storage proposal = proposals[proposalId];

        if (hasVoted[proposalId][msg.sender]) {
            revert AlreadyVoted();
        }

        if (block.timestamp > proposal.createdAt + VOTING_PERIOD) {
            revert VotingPeriodEnded();
        }

        if (proposal.executed) {
            revert ProposalAlreadyExecuted();
        }

        // Record the vote
        hasVoted[proposalId][msg.sender] = true;
        proposal.voteCount++;

        emit Voted(proposalId, msg.sender);
    }

    /**
     * @dev Returns a list of proposals that have passed and can be executed
     * @return An array of proposal IDs that have passed and are ready for execution
     */
    function getWinningProposals() public view returns (uint256[] memory) {
        // Create a temporary array to store winning proposal IDs (max size is all proposals)
        uint256[] memory temp = new uint256[](proposals.length);
        uint256 count = 0;

        // Find all winning proposals in a single loop
        for (uint256 i = 0; i < proposals.length; i++) {
            Proposal storage proposal = proposals[i];

            // Check if the proposal has passed and is ready for execution
            if (
                !proposal.executed &&
                proposal.voteCount > memberCount / 2 &&
                block.timestamp > proposal.createdAt + VOTING_PERIOD
            ) {
                temp[count] = i;
                count++;
            }
        }

        // Create the final array of exactly the right size
        uint256[] memory winningProposals = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            winningProposals[i] = temp[i];
        }

        return winningProposals;
    }

    /**
     * @dev Executes all proposals that have passed and are ready to be executed
     */
    function executeProposals() external onlyMember {
        uint256[] memory winningProposals = getWinningProposals();

        if (winningProposals.length == 0) {
            revert NoPassedProposals();
        }

        for (uint256 i = 0; i < winningProposals.length; i++) {
            uint256 proposalId = winningProposals[i];
            Proposal storage proposal = proposals[proposalId];

            // Check if we have enough funds
            if (proposal.value > treasuryBalance) {
                continue; // Skip this proposal if not enough funds
            }

            // Mark proposal as executed
            proposal.executed = true;

            // Reduce treasury balance
            treasuryBalance -= proposal.value;

            // Execute the proposal
            (bool success, ) = proposal.target.call{value: proposal.value}(
                proposal.data
            );
            if (!success) {
                revert ProposalExecutionFailed();
            }

            emit ProposalExecuted(proposalId);
        }
    }

    /**
     * @dev Executes a single proposal if it has passed and is ready
     * @param proposalId The ID of the proposal to execute
     */
    function executeSingleProposal(uint256 proposalId) external onlyMember {
        if (proposalId >= proposals.length) {
            revert ProposalDoesNotExist();
        }

        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) {
            revert ProposalAlreadyExecuted();
        }

        if (proposal.voteCount <= memberCount / 2) {
            revert ProposalNotPassed();
        }

        if (block.timestamp <= proposal.createdAt + VOTING_PERIOD) {
            revert VotingPeriodNotEnded();
        }

        if (proposal.value > treasuryBalance) {
            revert InsufficientFunds();
        }

        // Mark proposal as executed
        proposal.executed = true;

        // Reduce treasury balance
        treasuryBalance -= proposal.value;

        // Execute the proposal
        (bool success, ) = proposal.target.call{value: proposal.value}(
            proposal.data
        );
        if (!success) {
            revert ProposalExecutionFailed();
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Returns the number of proposals
     * @return The total count of proposals
     */
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @dev Returns information about a proposal
     * @param proposalId The ID of the proposal to get information about
     * @return proposer The address that created the proposal
     * @return description Brief description of the proposal
     * @return target The address that will be called if the proposal passes
     * @return value The amount of ETH to send with the call
     * @return createdAt When the proposal was created
     * @return voteCount How many votes the proposal has received
     * @return executed Whether the proposal has been executed
     */
    function getProposal(
        uint256 proposalId
    )
        external
        view
        returns (
            address proposer,
            string memory description,
            address target,
            uint256 value,
            uint256 createdAt,
            uint256 voteCount,
            bool executed
        )
    {
        if (proposalId >= proposals.length) {
            revert ProposalDoesNotExist();
        }

        Proposal storage proposal = proposals[proposalId];

        return (
            proposal.proposer,
            proposal.description,
            proposal.target,
            proposal.value,
            proposal.createdAt,
            proposal.voteCount,
            proposal.executed
        );
    }

    /**
     * @dev Accept ETH donations
     */
    receive() external payable {
        treasuryBalance += msg.value;
        emit FundsReceived(msg.sender, msg.value);
    }
}
