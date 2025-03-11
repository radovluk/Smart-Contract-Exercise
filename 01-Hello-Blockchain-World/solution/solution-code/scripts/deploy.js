const hre = require("hardhat");

async function main() {
  // Set the initial greeting message
  const initialGreeting = "Hello, Blockchain World!";

  // Deploy the Greeter contract with the initial greeting
  const greeter = await ethers.deployContract("Greeter", [initialGreeting]);
  console.log(`Greeter contract deployed to: ${greeter.target}`);

  // Wait for the deployment to complete
  await greeter.waitForDeployment();

  // Retrieve the stored greeting from the contract
  const greeting = await greeter.greet();
  console.log(`Contract greeting: ${greeting}`);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
