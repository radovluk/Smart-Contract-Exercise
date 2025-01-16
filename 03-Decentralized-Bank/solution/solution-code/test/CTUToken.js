// Import necessary modules
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CTUToken Contract Test Suite", function () {
    async function deployCTUTokenFixture() {
        // Retrieve a list of accounts provided by Hardhat
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();
        
        const CTUToken = await ethers.getContractFactory("CTUToken");
        const ctuToken = await CTUToken.deploy();
        return { ctuToken, owner, addr1, addr2, addr3 };
    }

    describe("Deployment of the Token.", function () {
        it("Should deploy the CTUToken contract and have a valid address", async function () {
            const { ctuToken } = await deployCTUTokenFixture();
            expect(ctuToken.address).to.not.equal(0);
            expect(ctuToken.target).to.properAddress;
        });
    });
});