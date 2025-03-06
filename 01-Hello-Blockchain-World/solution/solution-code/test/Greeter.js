// Import the 'expect' function from Chai for assertions
const { expect } = require("chai");

// Test suite for the Greeter contract
describe("Greeter contract says Hello, Blockchain World!", function () {

    // Test to ensure the initial greeting is set correctly upon deployment
    it("Should set the initial greeting correctly.", async function () {

        // Define the initial greeting message
        const initialGreeting = "Hello, Blockchain World!";

        // Deploy the Greeter contract with the initial greeting
        const greeter = await ethers.deployContract("Greeter", [initialGreeting]);

        // Wait for the deployment to complete
        await greeter.waitForDeployment();

        // Retrieve the stored greeting from the contract
        const greeting = await greeter.greet();

        // Verify that the retrieved greeting matches the initial greeting
        expect(greeting).to.equal(initialGreeting);
    });
});