import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, ContractInterface } from "ethers"


describe("Testing the staking algorithm workflow", async() => {
    let ARTE721Contract: any;
    let ARTE1155Contract: any;
    let StakingContract: any;

    const accounts = await ethers.getSigners();
    const acc: string = accounts[0].address;
    const receiver: string = accounts[1].address;


    it("New Staker mint an ERC721 NFT", async(): Promise<void> => {
        ARTE721Contract = await ethers.deployContract(
            "ARTE721", [acc]
        );
        
        const tx = await ARTE721Contract.safeMint(
            receiver, 1, "");
        tx.wait(1);

        console.log(`Contract deployed to: ${await ARTE721Contract.getAddress()}\n`);
        
        expect(await ARTE721Contract.balanceOf(receiver)).to.equal(1);
        expect(await ARTE721Contract.ownerOf(1)).to.equal(receiver);
    });


    it("Owner of contract should mint ARTE1155 as reward NFT token"), async()=> {
        ARTE1155Contract = ethers.deployContract(
            "ARTE1155", [acc])
            
        const tx = ARTE1155Contract.mint(
            acc, 1, 100, "");

        expect(ARTE1155Contract.balanceOf(acc, 1)).to.equal(100);

        // After Transfering 10 token from acc -> receiver account
        const transfer_tx = ARTE1155Contract.safeTransferFrom(
            acc, receiver, 1, 10, "");
        transfer_tx.wait(1);

        expect(ARTE1155Contract.balanceOf(acc, 1)).to.equal(90);
        expect(ARTE1155Contract.balanceOf(receiver, 1)).to.equal(10);
    }


    it("After minting the ARTE share-holder decide to stake his own NFT", async() => {
        StakingContract = ethers.deployContract(
            "StakingContract", [acc]);
        
        expect(ARTE721Contract.balanceOf(receiver)).to.equal(1);
    })
})


