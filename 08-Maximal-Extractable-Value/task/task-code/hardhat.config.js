require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      mining: {
        auto: false, // disable auto mining (This means that transactions won't be mined instantly)
        interval: 500 // new block will be mined every 500 ms
      },
      mempool: {
        order: "priority" // transactions will be ordered by priority based on the priority fee
      },
      gas: "auto", // Allow multiple transactions in the mempool
      initialBaseFeePerGas: 1000000000, // 1 gwei initial base fee
      hardfork: "london" // Ensure we're using the London hardfork which includes EIP-1559
    }
  },
  mocha: {
    timeout: 60000
  }
};