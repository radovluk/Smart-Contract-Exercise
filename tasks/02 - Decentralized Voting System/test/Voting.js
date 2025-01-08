const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("Voting", function () {
  /**
   * Fixture to deploy the Voting contract.
   * Re-runs between tests to ensure each test starts from a clean state.
   */
  async function deployVotingFixture() {
    const [owner, voter1, voter2] = await ethers.getSigners();

    // 1. Get the contract factory
    const Voting = await ethers.getContractFactory("Voting");

    // 2. Deploy the contract
    const voting = await Voting.deploy();

    // Return variables needed in later tests
    return { voting, owner, voter1, voter2 };
  }

  describe("Deployment", function () {
    it("Should deploy the contract successfully", async function () {
      const { voting } = await loadFixture(deployVotingFixture);
      expect(voting.target).to.properAddress;
    });

    it("Should set the right owner", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);
      expect(await voting.owner()).to.equal(owner.address);
    });
  });

  describe("Candidates", function () {
    it("Should allow the owner to add candidates", async function () {
      const { voting, owner } = await loadFixture(deployVotingFixture);

      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      const candidateCount = await voting.getCandidateCount();
      expect(candidateCount).to.equal(2);

      const candidate1 = await voting.getCandidate(0);
      expect(candidate1[0]).to.equal("Alice");

      const candidate2 = await voting.getCandidate(1);
      expect(candidate2[0]).to.equal("Bob");
    });

    it("Should not allow non-owners to add candidates", async function () {
      const { voting, voter1 } = await loadFixture(deployVotingFixture);

      await expect(voting.connect(voter1).addCandidate("Alice")).to.be.revertedWith("Not the contract owner");
    });
  });

  describe("Voting", function () {
    it("Should allow a voter to cast a vote", async function () {
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      await voting.connect(owner).addCandidate("Alice");

      await voting.connect(voter1).vote(0);

      const candidate = await voting.getCandidate(0);
      expect(candidate[1]).to.equal(1);
    });

    it("Should not allow a voter to vote more than once", async function () {
      const { voting, owner, voter1 } = await loadFixture(deployVotingFixture);

      await voting.connect(owner).addCandidate("Alice");

      await voting.connect(voter1).vote(0);

      await expect(voting.connect(voter1).vote(0)).to.be.revertedWith("Already voted");
    });

    it("Should allow multiple voters to vote", async function () {
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      await voting.connect(owner).addCandidate("Alice");

      await voting.connect(voter1).vote(0);
      await voting.connect(voter2).vote(0);

      const candidate = await voting.getCandidate(0);
      expect(candidate[1]).to.equal(2);
    });
  });

  describe("Results", function () {
    it("Should return the correct vote count for a candidate", async function () {
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      await voting.connect(voter1).vote(0);
      await voting.connect(voter2).vote(1);

      const candidate1 = await voting.getCandidate(0);
      const candidate2 = await voting.getCandidate(1);
      expect(candidate1[1]).to.equal(1);
      expect(candidate2[1]).to.equal(1);
    });

    it("Should return the winning candidate", async function () {
      const { voting, owner, voter1, voter2 } = await loadFixture(deployVotingFixture);

      await voting.connect(owner).addCandidate("Alice");
      await voting.connect(owner).addCandidate("Bob");

      await voting.connect(voter1).vote(0);
      await voting.connect(voter2).vote(0);

      const winnerIndex = await voting.winningCandidate();
      expect(winnerIndex).to.equal(0);
    });
  });
});
