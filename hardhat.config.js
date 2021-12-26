require("@nomiclabs/hardhat-waffle");

module.exports = {
  mainnet: {
    url: "https://mainnet.infura.io/v3/<your_infura_key>",
    accounts: [0x0]
  },
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  }
};
