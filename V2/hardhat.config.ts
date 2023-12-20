import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
import "solidity-coverage";
// require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

const INFURA_API_KEY = process.env.WEB3_INFURA_ENDPOINT;

const config: HardhatUserConfig = {
  solidity: "0.8.20",

  gasReporter: {
    enabled: true,
    outputFile: "gas-report.txt",
    currency: "USD",
    token: "ETH",
    gasPrice: 20,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || "",
    noColors: true,
  }
};

export default config;
