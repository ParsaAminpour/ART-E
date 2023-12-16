import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, ContractInterface } from "ethers"
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { HardhatEthersProvider } from "@nomicfoundation/hardhat-ethers/internal/hardhat-ethers-provider";

describe("Testing the staking algorithm workflow", () => {
    let ARTE721Contract: any;
    let ARTE1155Contract: any;

    let accounts: HardhatEthersSigner[];
    let acc: HardhatEthersSigner;
    let receiver: HardhatEthersSigner;

    beforeEach(async() => {
        accounts = await ethers.getSigners();
        [acc, receiver] = await ethers.getSigners();

        ARTE721Contract = await ethers.deployContract(
            "ARTE721", [acc]
        );

        ARTE1155Contract = ethers.deployContract(
            "ARTE1155", [acc])
    })

    it("New Staker mint an ERC721 NFT", async(): Promise<void> => {        
        const tx = await ARTE721Contract.safeMint(
            receiver, 1, "");
        tx.wait(1);

        console.log(`Contract deployed to: ${await ARTE721Contract.getAddress()}\n`);
        
        expect(await ARTE721Contract.balanceOf(receiver)).to.equal(1);
        expect(await ARTE721Contract.ownerOf(1)).to.equal(receiver.address);
    });


    // NOTE: The pendning status of this test case bug should be solve ASAP
    it("Owner of contract should mint ARTE1155 as reward NFT token"), async()=> {
        const tx = await ARTE1155Contract.mint(
            acc, 1, 100, "");
        tx.wait(1);
            
        expect(await ARTE1155Contract.balanceOf(acc, 1)).to.equal(100);

        // After Transfering 10 token from acc -> receiver account
        const transfer_tx = await ARTE1155Contract.safeTransferFrom(
            acc, receiver, 1, 10, "");
        transfer_tx.wait();

        expect(await ARTE1155Contract.balanceOf(acc, 1)).to.equal(90);
        expect(await ARTE1155Contract.balanceOf(receiver, 1)).to.equal(10);
    }
})


