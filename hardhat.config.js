require("@nomiclabs/hardhat-waffle");
require('dotenv').config({ path: __dirname + '/.env' })

const { MAINNET_API_URL, ALCHEMY_ROPSTEN_API_URL, PRIVATE_KEY } = process.env;
module.exports = {
  defaultNetwork: "ropsten",

  networks: {
    hardhat: {},
    ropsten: {
      url: ALCHEMY_ROPSTEN_API_URL,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    mainnet: {
      url: MAINNET_API_URL,
      accounts: [`0x${PRIVATE_KEY}`]
    },
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
