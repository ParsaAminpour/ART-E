import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Contract, ContractInterface } from "ethers"
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ConnectionAcquireTimeoutError } from "sequelize";
import { setMaxIdleHTTPParsers } from "http";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Testing the staking algorithm workflow", () => {
    let ARTE721Contract: any;
    let ARTE1155Contract: any;
    let StakingContract: any;

    let accounts: HardhatEthersSigner[];
    let acc: HardhatEthersSigner;
    let receiver: HardhatEthersSigner;
    let another_acc: HardhatEthersSigner;
    let ConnectedStakingContract: any;


    // in this section receiver address minted 1 ARTE721 nft
    beforeEach(async() => {
        accounts = await ethers.getSigners();
        [acc, receiver, another_acc] = await ethers.getSigners();

        ARTE721Contract = await ethers.deployContract("ARTE721", [acc]);
        ARTE1155Contract = await ethers.deployContract("ARTE1155", [acc]);

        await ARTE721Contract.safeMint(receiver, 1, "");

        const StakingFactory = await ethers.getContractFactory("StakingContract");
        StakingContract = await StakingFactory.deploy(
            1, // reward_amount -> R
            { from: acc.address })

        ConnectedStakingContract = await StakingContract.connect(
            receiver);    

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
                .to.equal(1);
            
            expect(await StakingContract.const_reward())
                .to.equal(1);
        })
    });
    
    describe("Staking function", () => {
        it("checking the function requirements", async() => {
            expect(await ConnectedStakingContract.address)
                .to.equal(StakingContract.address);
            
            // for incorrect amount
            await expect(ConnectedStakingContract.Staking(another_acc.address, 1))
                .to.be.revertedWith(
                    "staker must be the owner of the token"
                )
            
        });

        // Staking function workflow analyzing
        it("checking the state variable midifications after Staking", async() => {
            // State variable before calling Staking function
            expect(await ConnectedStakingContract.getBalance(receiver.address))
                .to.equal(0);

            await ConnectedStakingContract.Staking(receiver.address, 1);
            
            expect(await ARTE721Contract.getTotalStaked()).to.equal(1);

            expect(await ConnectedStakingContract.getUserTokenPerReward(receiver.address))
                .to.equal(BigInt(1e18));
        });

        it("checking the update_user_token_reward workflow", async() => {})
    });


    // test cases related to withdraw function's work-flow
    describe("Withdraw function", () => {
        it("checking the function requirements", async() => {

            
            await expect(ConnectedStakingContract.Withdrawing(another_acc.address))
                .to.be.revertedWith("You have not been included to this staking smart contract yet");
        })

        it("checking the state variable midifications after Staking", async() => {
            await ConnectedStakingContract.Staking(receiver.address, 1);

            const _receiver_balance = await ConnectedStakingContract.getBalance(receiver.address);
            const r = await ConnectedStakingContract.getUserTokenPerReward(receiver.address);
            const current_reward_claimed = await ConnectedStakingContract.getRewardAmountForEarn(receiver.address);

            console.log(_receiver_balance + '\n');
            console.log(`r is ${r} which is ${r / BigInt(1e18)}`);
            console.log(current_reward_claimed + '\n');
            

            
            // we should set time delay duration to testing staking algorithm work-flow
            await time.increase(3600);
            console.log('test')
            // mine a new block with timestamp `newTimestamp`;
        })
    })
});


