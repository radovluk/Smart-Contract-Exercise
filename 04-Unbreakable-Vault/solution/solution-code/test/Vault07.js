// Importing necessary modules
const { expect } = require("chai");

/**
 * Test Suite for the Vault07: You Shall Not Pass!
 */
describe("Vault07 Test Suite", function () {
    let vault;
    let player; // Signer representing the player
    let playerAddress; // Address of the player
    let vaultAddress; // Address of the vault contract

    before("Set up the challenge", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // For the purpouse of this test switch to the Sepolia test network
        await hre.switchNetwork("sepolia");

        // Using ethers.getContractAt to load the contract interface at the desired address
        vaultAddress = "0xa81C96B2216eDFfF8945e371dd581D13f8ECfbAD";
        const vaultAbi = [
            "function breachVault(bytes32 _password) public returns (bool)",
            "function lastSolver() public view returns (address)"
        ];
        vault = await ethers.getContractAt(vaultAbi, vaultAddress);

        // Retrieve the list of signers
        [player] = await ethers.getSigners();

        // Get the player's address
        playerAddress = await player.getAddress();

        // Now you can call functions on the vault contract as if you're on Sepolia
        console.log("Contract loaded from forked Sepolia network at", vaultAddress);
        console.log("Player's address:", playerAddress);
    });

    /**
     * Here's where you try to breach the vault.
     * Fill in your logic to figure out the password and call the breachVault function.
     */
    it("Execution of the player's code", async function () {
        // Storage layout
        // ╭------------+---------+------+--------+-------+----------------------------╮
        // | Name       | Type    | Slot | Offset | Bytes | Contract                   |
        // +===========================================================================+
        // | lastSolver | address | 0    | 0      | 20    | Vault07.sol:Vault07 |
        // |------------+---------+------+--------+-------+----------------------------|
        // | small1     | uint8   | 0    | 20     | 1     | Vault07.sol:Vault07 |
        // |------------+---------+------+--------+-------+----------------------------|
        // | small2     | uint16  | 0    | 21     | 2     | Vault07.sol:Vault07 |
        // |------------+---------+------+--------+-------+----------------------------|
        // | isActive   | bool    | 0    | 23     | 1     | Vault07.sol:Vault07 |
        // |------------+---------+------+--------+-------+----------------------------|
        // | big1       | uint256 | 1    | 0      | 32    | Vault07.sol:Vault07 |
        // |------------+---------+------+--------+-------+----------------------------|
        // | hashData   | bytes32 | 2    | 0      | 32    | Vault07.sol:Vault07 |
        // |------------+---------+------+--------+-------+----------------------------|
        // | big2       | uint256 | 3    | 0      | 32    | Vault07.sol:Vault07 |
        // |------------+---------+------+--------+-------+----------------------------|
        // | password   | string  | 4    | 0      | 32    | Vault07.sol:Vault07 |
        // ╰------------+---------+------+--------+-------+----------------------------╯

        // Read slot 4
        slotValue = await ethers.provider.getStorage(vaultAddress, 4);
        console.log("Slot4:", slotValue);
        
        // Replace the last byte with 0x00 so that it becomes a valid bytes32 string:
        // In this case, you can also use the approach from challenge Vault06
        // slotValue = slotValue.substring(0, slotValue.length - 2) + "00";

        // Get the last byte (metadata)
        const tagHex = slotValue.slice(-2);
        const tag = parseInt(tagHex, 16);

        // With the new encoding, length = tag / 2
        const length = tag / 2; // 38/2 = 19

        // The actual string is stored in the first `length` bytes.
        // Each byte is represented by 2 hex characters, so we take length*2 hex digits.
        const actualDataHex = "0x" + slotValue.slice(2, 2 + length * 2);

        // Decode the proper string:
        const actualPassword = ethers.toUtf8String(actualDataHex);
        console.log("Password: ", actualPassword);

        // Compute the hash in the same way Solidity does with abi.encodePacked
        const hashedPassword = ethers.solidityPackedKeccak256(
            ["string", "address"], 
            [actualPassword, playerAddress]
        );

        console.log(hashedPassword);

        const tx = await vault.breachVault(hashedPassword);
        tx.wait();
    });

    after("Success conditions", async function () {
        /** DO NOT CHANGE ANYTHING HERE */

        // Expect the last solver to be the player
         // Verify lastSolver == your wallet address
        expect(await vault.lastSolver(), "Last solver is not the player").to.equal(playerAddress);
    });
});
