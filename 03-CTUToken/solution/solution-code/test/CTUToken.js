// `LoadFixture` is used to share common setups between tests.
// Using this simplifies the tests and makes them run faster.
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

// Importing Chai to use its asserting functions.
const { expect } = require("chai");

describe("CTUToken Contract Test Suite", function () {
    // Fixture to deploy the contract and set up initial state
    async function deployCTUTokenFixture() {
        // Retrieve a list of accounts provided by Hardhat
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();

        // Deploy the CTUToken contract
        const ctuToken = await ethers.deployContract("CTUToken");

        // Waiting for the transaction to be mined
        await ctuToken.waitForDeployment();

        // Fixtures can return anything you consider useful for your tests
        return { ctuToken, owner, addr1, addr2, addr3 };
    }

    // Test suite for deployment-related tests
    describe("Deployment", function () {
        it("Should set the right name", async function () {
            const { ctuToken } = await loadFixture(deployCTUTokenFixture);
            expect(await ctuToken.name()).to.equal("CTU Token");
        });

        it("Should set the right symbol", async function () {
            const { ctuToken } = await loadFixture(deployCTUTokenFixture);
            expect(await ctuToken.symbol()).to.equal("CTU");
        });

        it("Should set the correct decimals", async function () {
            const { ctuToken } = await loadFixture(deployCTUTokenFixture);
            expect(await ctuToken.decimals()).to.equal(18);
        });

        it("Should assign the total supply of the token to the owner", async function () {
            const { ctuToken, owner } = await loadFixture(deployCTUTokenFixture);
            const totalSupply = await ctuToken.totalSupply();
            const ownerBalance = await ctuToken.balanceOf(owner.address);
            expect(ownerBalance).to.equal(totalSupply);
        });
    });

    // Test suite for ERC-20 standard functions
    describe("ERC-20 Functions", function () {
        // Test suite for balanceOf function
        describe("balanceOf", function () {
            it("Should return correct balance for owner", async function () {
                const { ctuToken, owner } = await loadFixture(deployCTUTokenFixture);
                const ownerBalance = await ctuToken.balanceOf(owner.address);
                expect(ownerBalance).to.equal(await ctuToken.totalSupply());
            });

            it("Should return zero balance for non-owner accounts initially", async function () {
                const { ctuToken, addr1 } = await loadFixture(deployCTUTokenFixture);
                const addr1Balance = await ctuToken.balanceOf(addr1.address);
                expect(addr1Balance).to.equal(0);
            });
        });

        // Test suite for transfer function
        describe("transfer", function () {
            it("Should transfer tokens successfully and update balances", async function () {
                const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
                const transferAmount = ethers.parseUnits("1000", 18);

                await expect(() => ctuToken.transfer(addr1.address, transferAmount))
                    .to.changeTokenBalance(ctuToken, addr1, transferAmount);

                await expect(() => ctuToken.transfer(addr1.address, transferAmount))
                    .to.changeTokenBalance(ctuToken, owner, -transferAmount);

                await expect(ctuToken.transfer(addr1.address, transferAmount))
                    .to.emit(ctuToken, "Transfer")
                    .withArgs(owner.address, addr1.address, transferAmount);
            });

            it("Should fail when transferring to zero address", async function () {
                const { ctuToken } = await loadFixture(deployCTUTokenFixture);
                const transferAmount = ethers.parseUnits("1000", 18);

                await expect(
                    ctuToken.transfer(ethers.ZeroAddress, transferAmount)
                ).to.be.reverted;
            });

            it("Should fail when sender has insufficient balance", async function () {
                const { ctuToken, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
                const transferAmount = ethers.parseUnits("1000", 18);

                // addr1 has 0 balance initially
                await expect(
                    ctuToken.connect(addr1).transfer(addr2.address, transferAmount)
                ).to.be.reverted;
            });

            it("Should allow transferring zero tokens", async function () {
                const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
                const transferAmount = 0;

                await expect(ctuToken.transfer(addr1.address, transferAmount))
                    .to.emit(ctuToken, "Transfer")
                    .withArgs(owner.address, addr1.address, transferAmount);

                expect(await ctuToken.balanceOf(owner.address)).to.equal(await ctuToken.totalSupply());
                expect(await ctuToken.balanceOf(addr1.address)).to.equal(0);
            });
        });

        // Test suite for approve and allowance functions
        describe("approve and allowance", function () {
            it("Should approve allowance correctly", async function () {
                const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("5000", 18);

                await expect(ctuToken.approve(addr1.address, approveAmount))
                    .to.emit(ctuToken, "Approval")
                    .withArgs(owner.address, addr1.address, approveAmount);

                expect(await ctuToken.allowance(owner.address, addr1.address)).to.equal(approveAmount);
            });

            it("Should overwrite previous allowance", async function () {
                const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
                const firstApprove = ethers.parseUnits("5000", 18);
                const secondApprove = ethers.parseUnits("3000", 18);

                await ctuToken.approve(addr1.address, firstApprove);
                await expect(ctuToken.approve(addr1.address, secondApprove))
                    .to.emit(ctuToken, "Approval")
                    .withArgs(owner.address, addr1.address, secondApprove);

                expect(await ctuToken.allowance(owner.address, addr1.address)).to.equal(secondApprove);
            });

            it("Should fail when approving zero address as spender", async function () {
                const { ctuToken, owner } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("1000", 18);

                await expect(
                    ctuToken.approve(ethers.ZeroAddress, approveAmount)
                ).to.be.reverted;
            });

            it("Should allow setting allowance to zero", async function () {
                const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("1000", 18);

                await ctuToken.approve(addr1.address, approveAmount);
                await expect(ctuToken.approve(addr1.address, 0))
                    .to.emit(ctuToken, "Approval")
                    .withArgs(owner.address, addr1.address, 0);

                expect(await ctuToken.allowance(owner.address, addr1.address)).to.equal(0);
            });
        });

        // Test suite for transferFrom function
        describe("transferFrom", function () {
            it("Should transfer tokens using allowance and update receiver's balance", async function () {
                const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("1000", 18);
                const transferAmount = ethers.parseUnits("500", 18);

                // Owner approves addr1 to spend 1000 tokens
                await ctuToken.approve(addr1.address, approveAmount);

                // addr1 transfers 500 tokens from owner to addr2
                await expect(ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount))
                    .to.changeTokenBalance(ctuToken, addr2, transferAmount);
            });

            it("Should reduce the balance of the owner after transfer", async function () {
                const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("1000", 18);
                const transferAmount = ethers.parseUnits("500", 18);

                // Owner approves addr1 to spend 1000 tokens
                await ctuToken.approve(addr1.address, approveAmount);

                // addr1 transfers 500 tokens from owner to addr2
                await expect(ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount))
                    .to.changeTokenBalance(ctuToken, owner, -transferAmount);
            });

            it("Should fail when transferring to zero address", async function () {
                const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("1000", 18);
                const transferAmount = ethers.parseUnits("500", 18);

                await ctuToken.approve(addr1.address, approveAmount);

                await expect(
                    ctuToken.connect(addr1).transferFrom(owner.address, ethers.ZeroAddress, transferAmount)
                ).to.be.reverted;
            });

            it("Should fail when transferring more than balance", async function () {
                const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
                // Add one to the total number of tokens (1n is big int)
                approveAmount = await ctuToken.totalSupply() + 1n;
                transferAmount = await ctuToken.totalSupply() + 1n;

                await ctuToken.approve(addr1.address, approveAmount);

                await expect(
                    ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount)
                ).to.be.reverted;
            });

            it("Should fail when transferring more than allowance", async function () {
                const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("500", 18);
                const transferAmount = ethers.parseUnits("600", 18);

                await ctuToken.approve(addr1.address, approveAmount);

                await expect(
                    ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount)
                ).to.be.reverted;
            });

            it("Should allow multiple transfers up to the allowance", async function () {
                const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
                const approveAmount = ethers.parseUnits("1000", 18);
                const firstTransfer = ethers.parseUnits("400", 18);
                const secondTransfer = ethers.parseUnits("600", 18);

                await ctuToken.approve(addr1.address, approveAmount);

                // First transfer
                await expect(
                    ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, firstTransfer)
                )
                    .to.emit(ctuToken, "Transfer")
                    .withArgs(owner.address, addr2.address, firstTransfer);

                // Second transfer
                await expect(
                    ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, secondTransfer)
                )
                    .to.emit(ctuToken, "Transfer")
                    .withArgs(owner.address, addr2.address, secondTransfer);

                expect(await ctuToken.balanceOf(addr2.address)).to.equal(firstTransfer + secondTransfer);
                expect(await ctuToken.allowance(owner.address, addr1.address)).to.equal(0);
            });

            it("Should allow transferring zero tokens via transferFrom", async function () {
                const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
                const transferAmount = 0;

                await expect(() => ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount))
                    .to.changeTokenBalance(ctuToken, addr2, transferAmount);

                expect(await ctuToken.balanceOf(owner.address)).to.equal(await ctuToken.totalSupply());
                expect(await ctuToken.balanceOf(addr2.address)).to.equal(0);
            });
        });
    });

    // Test suite for event emission tests
    describe("Events", function () {
        it("Should emit Transfer event on successful transfer", async function () {
            const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
            const transferAmount = ethers.parseUnits("2000", 18);

            await expect(ctuToken.transfer(addr1.address, transferAmount))
                .to.emit(ctuToken, "Transfer")
                .withArgs(owner.address, addr1.address, transferAmount);
        });

        it("Should emit Approval event on successful approve", async function () {
            const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
            const approveAmount = ethers.parseUnits("3000", 18);

            await expect(ctuToken.approve(addr1.address, approveAmount))
                .to.emit(ctuToken, "Approval")
                .withArgs(owner.address, addr1.address, approveAmount);
        });

        it("Should emit Transfer event on transferFrom", async function () {
            const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
            const approveAmount = ethers.parseUnits("1000", 18);
            const transferAmount = ethers.parseUnits("700", 18);

            await ctuToken.approve(addr1.address, approveAmount);

            await expect(
                ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount)
            )
                .to.emit(ctuToken, "Transfer")
                .withArgs(owner.address, addr2.address, transferAmount);
        });
    });

    // Test suite for edge case tests
    describe("Edge Cases", function () {
        it("Should handle multiple approvals correctly", async function () {
            const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
            const approveAmount1 = ethers.parseUnits("500", 18);
            const approveAmount2 = ethers.parseUnits("1500", 18);

            await ctuToken.approve(addr1.address, approveAmount1);
            expect(await ctuToken.allowance(owner.address, addr1.address)).to.equal(approveAmount1);

            await ctuToken.approve(addr2.address, approveAmount2);
            expect(await ctuToken.allowance(owner.address, addr2.address)).to.equal(approveAmount2);
        });

        it("Should not allow non-approved spender to transfer tokens", async function () {
            const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
            const transferAmount = ethers.parseUnits("100", 18);

            // addr1 has no allowance
            await expect(
                ctuToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount)
            ).to.be.reverted;
        });

        it("Should correctly handle total supply after multiple transfers", async function () {
            const { ctuToken, owner, addr1, addr2 } = await loadFixture(deployCTUTokenFixture);
            const transferAmount1 = ethers.parseUnits("1000", 18);
            const transferAmount2 = ethers.parseUnits("2000", 18);

            await ctuToken.transfer(addr1.address, transferAmount1);
            await ctuToken.transfer(addr2.address, transferAmount2);

            const totalSupply = await ctuToken.totalSupply();
            const ownerBalance = await ctuToken.balanceOf(owner.address);
            const addr1Balance = await ctuToken.balanceOf(addr1.address);
            const addr2Balance = await ctuToken.balanceOf(addr2.address);

            expect(ownerBalance + addr1Balance + addr2Balance).to.equal(totalSupply);
        });

        it("Should not allow integer overflow/underflow", async function () {
            const { ctuToken, owner, addr1 } = await loadFixture(deployCTUTokenFixture);
            const maxUint = ethers.MaxUint256;

            // Attempt to approve MaxUint256
            await expect(ctuToken.approve(addr1.address, maxUint))
                .to.emit(ctuToken, "Approval")
                .withArgs(owner.address, addr1.address, maxUint);

            // Attempt to transfer more than balance
            await expect(
                ctuToken.transfer(addr1.address, maxUint)
            ).to.be.reverted;
        });
    });
});
