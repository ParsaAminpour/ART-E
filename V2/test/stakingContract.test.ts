import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Contract, ContractInterface } from "ethers"

describe("Testing the staking algorithm workflow", async() => {
    let ARTE721Contract: any;
    let ARTE1155Contract: any;
    let StakingContract: any;

    const accounts = await ethers.getSigners();
    const acc: string = accounts[0].address;
    const receiver: string = accounts[1].address;

    before(async() => {
        ARTE721Contract = await ethers.deployContract("ARTE721", [acc]);
        ARTE1155Contract = await ethers.deployContract("ARTE1155", [acc]);

        const StakingFactory = await ethers.getContractFactory("StakingContract");
        StakingContract = await StakingFactory.deploy(
            ARTE1155Contract.getAddress(),
            1,
            { from: acc})
        await StakingContract.deployed();

        console.log(`Contract deployed to: ${await StakingContract.getAddress()}\n`);
    })
    it("Checking Staking contract constructor sets correctly", async() => {
        expect(await StakingContract.tokenReward())
            .to.equal(ARTE1155Contract.getAddress());
    })
})


