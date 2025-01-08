// Import necessary modules from Hardhat and Chai
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

// Describe the test suite for the Voting contract
describe("Voting Contract Test Suite", function () {
  /**
   * Fixture to deploy the Voting contract.
   * Re-runs between tests to ensure each test starts from a clean state.
   */
  async function deployVotingFixture() {
    // Retrieve a list of accounts provided by Hardhat
    const [owner, voter1, voter2, voter3, voter4, voter5, nonOwner] = await ethers.getSigners();

    // 1. Get the contract factory for the Voting contract
    const Voting = await ethers.getContractFactory("Voting");

    // 2. Deploy the Voting contract
    const voting = await Voting.deploy();

    // Return the deployed contract instance and the signers for use in tests
    return { voting, owner, voter1, voter2, voter3, voter4, voter5, nonOwner };
  }

  // Test suite for Deployment-related tests
  describe("Deployment", function () {
    it("Should deploy the contract successfully and have a valid address", async function () {
      const { voting } = await loadFixture(deployVotingFixture);
      expect(voting.target).to.properAddress;
    });

    it("Should set the right owner", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);
      expect(await voting.owner()).to.equal(owner.address);
    });

    it("Should initialize with zero candidates", async function () {
      const { voting } = await loadFixture(deployVotingFixture);
      const count = await voting.getCandidateCount();
      expect(count).to.equal(0);
    });
  });

  // Test suite for Access Control
  describe("Access Control", function () {
    it("Only owner can add candidates", async function () {
      const { voting, owner, nonOwner } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate
      await expect(voting.connect(owner).addCandidate("Alice")).to.not.be.reverted;

      // Non-owner attempts to add a candidate
      await expect(voting.connect(nonOwner).addCandidate("Bob")).to.be.reverted;
    });
  });

  // Test suite for Candidate-related tests
  describe("Candidates Management", function () {
    it("Should allow the owner to add multiple candidates", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);

      // Owner adds multiple candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");
      await voting.connect(owner).addCandidate("Charlie");

      const count = await voting.getCandidateCount();
      expect(count).to.equal(3);

      const candidate1 = await voting.getCandidate(0);
      expect(candidate1.name).to.equal("Alice");
      expect(candidate1.voteCount).to.equal(0);

      const candidate2 = await voting.getCandidate(1);
      expect(candidate2.name).to.equal("Bob");
      expect(candidate2.voteCount).to.equal(0);

      const candidate3 = await voting.getCandidate(2);
      expect(candidate3.name).to.equal("Charlie");
      expect(candidate3.voteCount).to.equal(0);
    });

    it("Should prevent adding candidates with empty names", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);

      await expect(voting.connect(owner).addCandidate("")).to.be.reverted;
    });

    it("Should allow adding candidates with duplicate names", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);

      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Alice");

      const count = await voting.getCandidateCount();
      expect(count).to.equal(2);

      const candidate1 = await voting.getCandidate(0);
      const candidate2 = await voting.getCandidate(1);
      expect(candidate1.name).to.equal("Alice");
      expect(candidate2.name).to.equal("Alice");
    });

    it("Should emit a CandidateAdded event upon successful addition", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);

      await expect(voting.connect(owner).addCandidate("Alice"))
        .to.emit(voting, 'CandidateAdded')
        .withArgs("Alice");
    });
  });

  // Test suite for Voting-related tests
  describe("Voting Mechanism", function () {
    it("Should allow a voter to cast a vote for a valid candidate", async function () {
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate
      await voting.connect(owner).addCandidate("Alice");

      // Voter1 casts a vote
      await expect(voting.connect(voter1).vote(0)).to.emit(voting, 'Voted').withArgs(voter1.address, 0);

      // Verify vote count
      const candidate = await voting.getCandidate(0);
      expect(candidate.voteCount).to.equal(1);
    });

    it("Should not allow voting for a non-existent candidate", async function () {
      const { voting, voter1 } = await loadFixture(deployVotingFixture);

      // Attempt to vote without adding any candidates
      await expect(voting.connect(voter1).vote(0)).to.be.reverted;
    });

    it("Should not allow a voter to vote more than once", async function () {
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate
      await voting.connect(owner).addCandidate("Alice");

      // Voter1 casts their first vote
      await voting.connect(voter1).vote(0);

      // Voter1 attempts to cast a second vote
      await expect(voting.connect(voter1).vote(0)).to.be.reverted;
    });

    it("Should allow multiple voters to vote for different candidates", async function () {
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      // Owner adds two candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Voter1 votes for Alice and Voter2 votes for Bob
      await voting.connect(voter1).vote(0);
      await voting.connect(voter2).vote(1);

      // Verify vote counts
      const candidate1 = await voting.getCandidate(0);
      const candidate2 = await voting.getCandidate(1);
      expect(candidate1.voteCount).to.equal(1);
      expect(candidate2.voteCount).to.equal(1);
    });

    it("Should emit a Voted event upon successful voting", async function () {
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate
      await voting.connect(owner).addCandidate("Alice");

      // Voter1 casts a vote and expects an event
      await expect(voting.connect(voter1).vote(0))
        .to.emit(voting, 'Voted')
        .withArgs(voter1.address, 0);
    });
  });

  // Test suite for Results-related tests
  describe("Results and Winning Candidate", function () {
    it("Should return the correct vote count for each candidate", async function () {
      const { voting, owner, voter1, voter2, voter3 } = await loadFixture(deployVotingFixture);

      // Owner adds two candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Cast votes
      await voting.connect(voter1).vote(0); // Alice: 1
      await voting.connect(voter2).vote(1); // Bob: 1
      await voting.connect(voter3).vote(1); // Bob: 2

      // Retrieve and verify vote counts
      const candidate1 = await voting.getCandidate(0);
      const candidate2 = await voting.getCandidate(1);
      expect(candidate1.voteCount).to.equal(1);
      expect(candidate2.voteCount).to.equal(2);
    });

    it("Should correctly identify the winning candidate", async function () {
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      // Owner adds two candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Both voters vote for Bob
      await voting.connect(voter1).vote(1);
      await voting.connect(voter2).vote(1);

      // Retrieve the winning candidate index
      const winnerIndex = await voting.winningCandidate();
      expect(winnerIndex).to.equal(1); // Bob should be the winner
    });

    it("Should handle multiple candidates and determine the correct winner", async function () {
      const { voting, owner, voter1, voter2, voter3, voter4 } = await loadFixture(deployVotingFixture);

      // Owner adds three candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");
      await voting.connect(owner).addCandidate("Charlie");

      // Cast votes
      await voting.connect(voter1).vote(0); // Alice: 1
      await voting.connect(voter2).vote(1); // Bob: 1
      await voting.connect(voter3).vote(1); // Bob: 2
      await voting.connect(voter4).vote(2); // Charlie: 1

      // Retrieve the winning candidate index
      const winnerIndex = await voting.winningCandidate();
      expect(winnerIndex).to.equal(1); // Bob should be the winner
    });
  });

  // Test suite for Getter Functions
  describe("Getter Functions", function () {
    it("Should return the correct candidate details using getCandidate", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate
      await voting.connect(owner).addCandidate("Alice");

      // Retrieve candidate details
      const candidate = await voting.getCandidate(0);
      expect(candidate.name).to.equal("Alice");
      expect(candidate.voteCount).to.equal(0);
    });

    it("Should revert when accessing a candidate with an invalid index", async function () {
      const { voting } = await loadFixture(deployVotingFixture);

      // Attempt to access a candidate that doesn't exist
      await expect(voting.getCandidate(0)).to.be.reverted;
    });

    it("Should return the correct total number of candidates", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);

      // Initially, zero candidates
      let count = await voting.getCandidateCount();
      expect(count).to.equal(0);

      // Add candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Check count again
      count = await voting.getCandidateCount();
      expect(count).to.equal(2);
    });
  });

  // Test suite for Edge Cases
  describe("Edge Cases", function () {
    it("Should handle voting when no candidates are present", async function () {
      const { voting, voter1 } = await loadFixture(deployVotingFixture);

      // Attempt to vote without any candidates
      await expect(voting.connect(voter1).vote(0)).to.be.reverted;
    });

    it("Should handle multiple votes and ensure accurate vote tracking", async function () {
      const { voting, owner, voter1, voter2, voter3, voter4, voter5 } = await loadFixture(deployVotingFixture);

      // Owner adds three candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");
      await voting.connect(owner).addCandidate("Charlie");

      // Cast multiple votes
      await voting.connect(voter1).vote(0); // Alice: 1
      await voting.connect(voter2).vote(1); // Bob: 1
      await voting.connect(voter3).vote(1); // Bob: 2
      await voting.connect(voter4).vote(2); // Charlie: 1
      await voting.connect(voter5).vote(1); // Bob: 3

      // Verify vote counts
      const alice = await voting.getCandidate(0);
      const bob = await voting.getCandidate(1);
      const charlie = await voting.getCandidate(2);

      expect(alice.voteCount).to.equal(1);
      expect(bob.voteCount).to.equal(3);
      expect(charlie.voteCount).to.equal(1);

      // Verify the winner
      const winnerIndex = await voting.winningCandidate();
      expect(winnerIndex).to.equal(1); // Bob should be the winner
    });

    it("Should not allow the same address to vote multiple times across different candidates", async function () {
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      // Owner adds two candidates
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Voter1 votes for Alice
      await voting.connect(voter1).vote(0);

      // Voter1 attempts to vote for Bob
      await expect(voting.connect(voter1).vote(1)).to.be.reverted;
    });
  });
});
