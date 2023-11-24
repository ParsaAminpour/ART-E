import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const INFURA_API_LEY = process.env.WEB3_INFURA_ENDPOINT;

const config: HardhatUserConfig = {
  solidity: "0.8.19",
};

export default config;
