import { HardhatEthersHelpers } from "hardhat/types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, network } from "hardhat";
import deploy_arte1155 from "./deploy_arte1155";
import deploy_arte721 from "./deploy_arte721";
import chalk from "chalk";
import inquirer from "inquirer";
const log = console.log;
require("dotenv").config();


let accounts: HardhatEthersSigner[];
let reward_owner: HardhatEthersSigner;
let staker: HardhatEthersSigner;
let another_acc: HardhatEthersSigner;

let StakingContract: any;
let arte721_contract: any;
let arte1155_contract: any;


const delay = (ms: number): Promise<void> => {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    })
}

const generateAccounts = async(network: string): Promise<void> => {
    accounts = await ethers.getSigners(); // for future use-cases, not necessary
    [reward_owner, staker, another_acc] = await ethers.getSigners();
    // } else if (network == 'sepolia') {
    //     // manage sepolia accounts in here
    // } else {
    //     throw Error(`Unknown network ${network}`);
    // }
}

const main = async(): Promise<void> => {
    await generateAccounts("hardhat");

    const StakingContractFactory = await ethers.getContractFactory("StakingContract");
    const deployedStakingContract = StakingContractFactory.deploy(
        1, 
        {from : reward_owner.address });
    (await deployedStakingContract).waitForDeployment();
    
    StakingContract = (await deployedStakingContract).connect(reward_owner);
    
    
    const arte721_contract_address = await StakingContract.getARTE721();
    const arte1155_contract_address = await StakingContract.getARTE1155();
    
    arte721_contract = await ethers.getContractAt("ARTE721", arte721_contract_address);
    arte1155_contract = await ethers.getContractAt("ARTE1155", arte1155_contract_address);


    // logs
    // log(chalk.red("test"));
    log(`The ARTE721 contract deployed at ${await arte721_contract_address}`);
    log(`The ARTE1155 contract deployed at ${await arte1155_contract_address}`);
    log(`The StakingContract contract deployed at ${await StakingContract.getAddress()}`);

    log(`And the owner of ARTE721 is: ${await arte721_contract.owner()}`);
    log(`And the owner of ARTE1155 is: ${await arte1155_contract.owner()}`);
    log(`And the owner of StakingContract is: ${await StakingContract.owner()}`);


    log(`The reward owner address is : ${reward_owner.address}`);
    log(`The staker address is : ${staker.address}`);
    log(`The another account address is : ${another_acc.address}`);

    log("\n\n\n");


    const tx = await StakingContract.Staking(
        staker.address, 1, { from: reward_owner.address }
    );
    const res = await tx.wait();
    log(await arte721_contract.balanceOf(staker.address));
    
    // should be time sleeping at here before another staking

    const tx2 = await StakingContract.Staking(
        staker.address, 2, { from: reward_owner.address }
    )
    const res2 = await tx2.wait();

        
    const total_satked = await StakingContract.getTotalStaked();
    log(total_satked);

    // For debugging purposes
    const name_ = await arte721_contract.name();
    log('the name is');
    log(name_);

    // approving before withdrawing
    const contract_address = await StakingContract.getAddress();
    
    await arte721_contract.connect(staker.address);
    const approve_tx = await arte721_contract.approve(
        contract_address, 1);
    approve_tx.wait();


    log("\n\n\n");
    // There are some errors here:
    // Withdrawing function
    const tx3 = await StakingContract.Withdrawing(
        staker.address, 1
    )
    const res3 = tx3.wait();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})

// there are reward_owner, staker, and another_acc roles.

// 1. reward_owner will deploy StakingContract to stablish the Staking workflow.
// 2. reward_owner will deploy ARTE1155 smart contract via StakingContract deployment script.
// 2.5. reward_owner also will deploy ARTE721 smart contract for staker minting.

// 3. staker will mint his own ARTE721 smart contract to stake NFT on ARTE.
// 4. after 1 minute, another_acc will deploy his own ARTE721 smart contract as another staker.
// 5. after another 1 minute, staker will deploy his another own ARTE721 smart contract
//      to increase his staking capacity
// 6. staker will withdraw / burn his whole ARTE721 NFT token that he has staked to claim his reward.