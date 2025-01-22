require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      mining: {
        auto: false, // disable auto mining (This means that transactions won't be mined instantly)
        interval: 500, // new block will be mined every 500 ms
        mempool: {
          order: "priority", // transactions will be ordered by priority based on the priority fee
        }
      }
    }
  }
};