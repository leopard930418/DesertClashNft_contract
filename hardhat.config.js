require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
const { ApiKey } = require('./secrets.json');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.0",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  paths: {
    artifacts: "./src/artifacts",
  },
  networks: {
    hardhat: {},
    ropsten: {
      url: "https://ropsten.infura.io/v3/e61ce3c1ff0f439c8cc620c964b8ecef",
      accounts: [ApiKey],
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/2685ba1bcbf54312bb8683ddcc02f79d",
      accounts: [ApiKey],
      apiKey: `8ZFFIRUXPPWQ74H525YIX8NMZQ26M35RZR`
    },
    // mumbai: {
    //   url: "https://rpc-mumbai.maticvigil.com",
    //   accounts: [ApiKey],
    //   apiKey: 'https://polygon-mumbai.g.alchemy.com/v2/w16u7DEGP20MnCvzDamBYWkmt1mCI1xa'
    // },
    mumbai: {
      url: 'https://rpc-mumbai.maticvigil.com',
      // url: 'https://rpc-mumbai.matic.today',
      accounts: [ApiKey],
      // apiKey: `DDX84A74SWWTF7J1YEMPWT46FC86Q8YC11`
    },
    // tron: {
    //   url: "https://api.trongrid.io",
    //   accounts: [
    //     `TKhBEjmi877u3Hs1g4WsmQ3zsL4f6FYr9d`,
    //   ],
    // },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [ApiKey]
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [ApiKey]
    },
    
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: "DDX84A74SWWTF7J1YEMPWT46FC86Q8YC11"    // polygon api key
    // apiKey: "8ZFFIRUXPPWQ74H525YIX8NMZQ26M35RZR"
  },
};
