import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Contract, ContractInterface } from "ethers"
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Testing the staking algorithm workflow", () => {
    let ARTE721Contract: any;
    let ARTE1155Contract: any;
    let StakingContract: any;

    let accounts: HardhatEthersSigner[];
    let acc: HardhatEthersSigner;
    let receiver: HardhatEthersSigner;
    let another_acc: HardhatEthersSigner;

    beforeEach(async() => {
        accounts = await ethers.getSigners();
        [acc, receiver, another_acc] = await ethers.getSigners();

        ARTE721Contract = await ethers.deployContract("ARTE721", [acc]);
        ARTE1155Contract = await ethers.deployContract("ARTE1155", [acc]);

        await ARTE721Contract.safeMint(receiver, 1, "");

        const StakingFactory = await ethers.getContractFactory("StakingContract");
        StakingContract = await StakingFactory.deploy(
            ARTE721Contract.getAddress(),
            ARTE1155Contract.getAddress(),
            1,
            { from: acc.address })

        console.log(`Contract deployed to: ${await StakingContract.getAddress()}\n`);
    })

    describe('constructor', () => { 
        it("Checking Staking contract constructor sets correctly", async() => {
            const arte_contract_address = await StakingContract.arte_nft();
            expect(await arte_contract_address)
                .to.equal(await ARTE721Contract.getAddress());

            const token_reward_address = await StakingContract.tokenReward();
            expect(await token_reward_address)
                .to.equal(await ARTE1155Contract.getAddress());

            const stake_workflow = await StakingContract.workflow();
            expect(stake_workflow[1]) // which is total_staked
                .to.equal(10);
            
            expect(await StakingContract.const_reward())
                .to.equal(1);
        })
    });
    
    describe("Staking function", () => {
        it("checking the function requirements", async() => {
            const ConnectedStakingContract = await StakingContract.connect(
                receiver);

            expect(await ConnectedStakingContract.address)
                .to.equal(StakingContract.address);
            
            // for incorrect amount
            await expect(ConnectedStakingContract.Staking(another_acc.address, 10, 1))
                .to.be.revertedWith(
                    "staker must be the owner of the token"
                )
            
            await expect(ConnectedStakingContract.Staking(receiver.address, 0, 1))
                    .to.be.revertedWith(
                        "amount must be more than 0"
                    );
        });

        it("", async() => {
            
        })
    });
})


