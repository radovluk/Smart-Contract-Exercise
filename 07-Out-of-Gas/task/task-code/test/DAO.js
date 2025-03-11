const { expect } = require("chai");
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers');
const { time } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * Test Suite for the DAO Challenge: Save the DAO funds from the cat lovers
 */
describe("DAO Challenge", function () {
    let dao;
    let catCharity;
    let deployer, player, member1, member2, member3, member4;

    const MEMBERSHIP_FEE = ethers.parseEther("1");
    const INITIAL_TREASURY = ethers.parseEther("10.0"); // 10 ETH for the treasury
    const PLAYER_INITIAL_ETH_BALANCE = ethers.parseEther("2.5"); // 2.5 ETH for the player
    const VOTING_PERIOD = 1 * 24 * 60 * 60; // 1 day in seconds

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Get signers for test accounts
        [deployer, player, member1, member2, member3, member4] = await ethers.getSigners();

        // Deploy the CatCharity contract
        const CatCharity = await ethers.getContractFactory("CatCharity", deployer);
        catCharity = await CatCharity.deploy();

        // Deploy the DAO contract with initial treasury funds
        const DAO = await ethers.getContractFactory("DAO", deployer);
        dao = await DAO.deploy({ value: INITIAL_TREASURY });
        console.log("DAO deployed at:", dao.target);

        // Set up initial account balances
        await setBalance(player.address, PLAYER_INITIAL_ETH_BALANCE);

        // Have all members join the DAO (including player)
        console.log("Members joining the DAO...");
        await dao.connect(member1).joinDAO({ value: MEMBERSHIP_FEE });
        await dao.connect(member2).joinDAO({ value: MEMBERSHIP_FEE });
        await dao.connect(member3).joinDAO({ value: MEMBERSHIP_FEE });
        await dao.connect(member4).joinDAO({ value: MEMBERSHIP_FEE });
        await dao.connect(player).joinDAO({ value: MEMBERSHIP_FEE });

        // Verify that we have 5 members total
        const memberCount = await dao.memberCount();
        console.log(`DAO has ${memberCount} members`);
        expect(memberCount).to.equal(5);

        // Create a proposal to donate all treasury funds to the Cat Charity
        console.log("Creating proposal to donate all funds to Cat Charity...");
        const donateCalldata = "0x"; // Empty calldata for a donation
        const treasuryBalance = await dao.treasuryBalance();

        await dao.connect(member1).createProposal(
            "Donate all DAO funds to the Cat Charity!",
            catCharity.target,
            treasuryBalance, // Donate entire treasury
            donateCalldata
        );

        // The other 4 members (except player) vote on the cat charity proposal
        console.log("Members voting for the cat charity proposal...");
        await dao.connect(member1).vote(0);
        await dao.connect(member2).vote(0);
        await dao.connect(member3).vote(0);
        await dao.connect(member4).vote(0);

        // Get the current votes (should be 4, which is a majority with 5 members)
        const proposal = await dao.getProposal(0);
        console.log(`Cat Charity proposal has ${proposal[5]} votes out of ${memberCount} members`);
        expect(proposal[5]).to.be.above(memberCount / 2n);

        console.log("Initial DAO Treasury Balance:", ethers.formatEther(await dao.treasuryBalance()), "ETH");
        console.log("Cat Charity Initial Balance:", ethers.formatEther(await ethers.provider.getBalance(catCharity.target)), "ETH");
    });

    it("Execution of the player's code", async function () {
        // =========================
        // TODO: YOUR CODE GOES HERE
        // =========================
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Fast forward time to end the voting period
        console.log("Fast forwarding time to end voting period...");
        await time.increase(VOTING_PERIOD + 1);

        // Try to execute all proposals, which should fail
        try {
            console.log("Attempting to execute proposals...");
            await dao.connect(member1).executeProposals();
        } catch (error) {
            console.log(error.message);
        }

        // Verify that the Cat Charity proposal has not been executed
        const catCharityProposal = await dao.getProposal(0);
        expect(catCharityProposal[6], "The Cat Charity proposal should not have been executed").to.be.false;

        // Verify the treasury funds are still safe in the DAO
        const finalDAOBalance = await dao.treasuryBalance();
        console.log("Final DAO Treasury Balance:", ethers.formatEther(finalDAOBalance), "ETH");
        expect(finalDAOBalance, "Treasury balance should not have decreased").to.be.at.least(INITIAL_TREASURY);

        // Verify the Cat Charity didn't receive any funds
        const catCharityBalance = await ethers.provider.getBalance(catCharity.target);
        console.log("Final Cat Charity Balance:", ethers.formatEther(catCharityBalance), "ETH");
        expect(catCharityBalance, "Cat Charity should not have received any funds").to.equal(0);

        console.log("Success! You saved the DAO funds from the cat lovers!");
    });
});