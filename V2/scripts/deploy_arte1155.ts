import { HardhatEthersHelpers } from "hardhat/types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, network } from "hardhat";
import { error } from "console";
require("dotenv").config();

const mint_arte1155 = async() => {
    let ARTE1155Cotnract: any;

    let accounts: HardhatEthersSigner[];
    let reward_owner: HardhatEthersSigner;
    let staker: HardhatEthersSigner;

    
    accounts = await ethers.getSigners();
    [reward_owner, staker] = await ethers.getSigners();
    ARTE1155Cotnract = await ethers.deployContract("ARTE1155", [reward_owner]);

    console.log(`ARTE1155 deployed at ${await ARTE1155Cotnract.getAddress()}`);

    const reward_owner_balacne = await ARTE1155Cotnract.balanceOf(reward_owner, 1);

    console.log(reward_owner_balacne.toString());
}


mint_arte1155().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})

export default mint_arte1155;