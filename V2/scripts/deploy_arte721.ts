import { ethers } from "hardhat";
import Moralis from "moralis";
import fs from "fs";
import { prompts } from "prompts";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
require("dotenv").config();


const getAccounts = async(): Promise<void> => {
    const accounts = await ethers.getSigners();
    for(const acc of accounts) {
        console.log(`address: ${acc.address}\n`);
    }
}

type ipfs_result = {
    path: string;
    cid: any;
    size: number;
}

type file_type = {
    path: string;
    content: any;
}

const provider_ipfs = async(
    file: file_type[], moralis_api_key: string | undefined): Promise<any> => {
    
    await Moralis.start({
        apiKey: moralis_api_key,
    })

    const response = await Moralis.EvmApi.ipfs.uploadFolder({
        abi: file,
    })

    console.log(response.result);
    return response;
}

// Deploying ARTE ERC-721 smart contract
const deploy_arte = async(acc: HardhatEthersSigner,token_uri: string): Promise<void> => {
    // const accounts = await ethers.getSigners();
    // const acc = accounts[0].address;

    const arte_contract = await ethers.deployContract(
        "ARTE721", [acc]);
    
    console.log(await arte_contract.getAddress());

    const tx = await arte_contract.safeMint(
        acc.address, 1, token_uri
    )
    tx.wait(1);
    
    const relevant_token_uri = arte_contract.tokenURI(1);

    console.log(await relevant_token_uri);
    console.log("\n");
}

const generate_openai_picture = async(
    openai_key: string, text: string): Promise<string> => {
    return "";
}

const deploy_arte721 = async(acc: HardhatEthersSigner) => {
    const file_choiced: file_type[] = [
        {
            path: "./scripts/test_pic.png",
            content: fs.readFileSync("./scripts/test_pic.png", {encoding: 'base64'}),
        }
    ]

    const result = await provider_ipfs(file_choiced, process.env.MORALIS_API_KEY);
    const picture_uri_path = result.result[0].path;
    const picture_uri = picture_uri_path.slice(34);
    
    await deploy_arte(acc, picture_uri);
}


export default deploy_arte721;

