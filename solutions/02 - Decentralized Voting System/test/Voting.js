// Import necessary modules from Hardhat and Chai
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

// Describe the test suite for the Voting contract
describe("Voting", function () {
  /**
   * Fixture to deploy the Voting contract.
   * Re-runs between tests to ensure each test starts from a clean state.
   */
  async function deployVotingFixture() {
    // Retrieve a list of accounts provided by Hardhat
    const [owner, voter1, voter2] = await ethers.getSigners();

    // 1. Get the contract factory for the Voting contract
    const Voting = await ethers.getContractFactory("Voting");

    // 2. Deploy the Voting contract
    const voting = await Voting.deploy();

    // Return the deployed contract instance and the signers for use in tests
    return { voting, owner, voter1, voter2 };
  }

  // Test suite for Deployment-related tests
  describe("Deployment", function () {
    it("Should deploy the contract successfully", async function () {
      // Load the fixture to deploy a fresh contract instance
      const { voting } = await loadFixture(deployVotingFixture);
      
      // Check that the deployed contract has a proper address
      expect(voting.target).to.properAddress;
    });

    it("Should set the right owner", async function () {
      // Load the fixture
      const { voting, owner } = await loadFixture(deployVotingFixture);
      
      // Assert that the owner variable in the contract matches the deployer's address
      expect(await voting.owner()).to.equal(owner.address);
    });
  });

  // Test suite for Candidate-related tests
  describe("Candidates", function () {
    it("Should allow the owner to add candidates", async function () {
      // Load the fixture
      const { voting, owner } = await loadFixture(deployVotingFixture);

      // Owner adds two candidates: "Alice" and "Bob"
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Retrieve the total number of candidates added
      const candidateCount = await voting.getCandidateCount();
      expect(candidateCount).to.equal(2);

      // Retrieve and verify the first candidate's name
      const candidate1 = await voting.getCandidate(0);
      expect(candidate1[0]).to.equal("Alice");

      // Retrieve and verify the second candidate's name
      const candidate2 = await voting.getCandidate(1);
      expect(candidate2[0]).to.equal("Bob");
    });

    it("Should not allow non-owners to add candidates", async function () {
      // Load the fixture
      const { voting, voter1 } = await loadFixture(deployVotingFixture);

      // Attempt to add a candidate as a non-owner and expect it to be reverted with an error
      await expect(voting.connect(voter1).addCandidate("Alice")).to.be.revertedWith("Not the contract owner");
    });
  });

  // Test suite for Voting-related tests
  describe("Voting", function () {
    it("Should allow a voter to cast a vote", async function () {
      // Load the fixture
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate named "Alice"
      await voting.connect(owner).addCandidate("Alice");

      // Voter1 casts a vote for the first candidate (index 0)
      await voting.connect(voter1).vote(0);

      // Retrieve the candidate's details to verify the vote count
      const candidate = await voting.getCandidate(0);
      expect(candidate[1]).to.equal(1); // Expect voteCount to be 1
    });

    it("Should not allow a voter to vote more than once", async function () {
      // Load the fixture
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate named "Alice"
      await voting.connect(owner).addCandidate("Alice");

      // Voter1 casts their first vote
      await voting.connect(voter1).vote(0);

      // Voter1 attempts to cast a second vote and expects it to be reverted
      await expect(voting.connect(voter1).vote(0)).to.be.revertedWith("Already voted");
    });

    it("Should allow multiple voters to vote", async function () {
      // Load the fixture
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      // Owner adds a candidate named "Alice"
      await voting.connect(owner).addCandidate("Alice");

      // Voter1 and Voter2 both cast votes for the first candidate (index 0)
      await voting.connect(voter1).vote(0);
      await voting.connect(voter2).vote(0);

      // Retrieve the candidate's details to verify the total vote count
      const candidate = await voting.getCandidate(0);
      expect(candidate[1]).to.equal(2); // Expect voteCount to be 2
    });
  });

  // Test suite for Result-related tests
  describe("Results", function () {
    it("Should return the correct vote count for a candidate", async function () {
      // Load the fixture
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      // Owner adds two candidates: "Alice" and "Bob"
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Voter1 votes for "Alice" (index 0) and Voter2 votes for "Bob" (index 1)
      await voting.connect(voter1).vote(0);
      await voting.connect(voter2).vote(1);

      // Retrieve and verify the vote counts for both candidates
      const candidate1 = await voting.getCandidate(0);
      const candidate2 = await voting.getCandidate(1);
      expect(candidate1[1]).to.equal(1); // "Alice" should have 1 vote
      expect(candidate2[1]).to.equal(1); // "Bob" should have 1 vote
    });

    it("Should return the winning candidate", async function () {
      // Load the fixture
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      // Owner adds two candidates: "Alice" and "Bob"
      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      // Both Voter1 and Voter2 vote for "Bob" (index 1)
      await voting.connect(voter1).vote(1);
      await voting.connect(voter2).vote(1);

      // Retrieve the index of the winning candidate
      const winnerIndex = await voting.winningCandidate();
      expect(winnerIndex).to.equal(1); // Expect "Alice" (index 0) to be the winner
    });
  });
});
