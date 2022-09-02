from email import header
from brownie import Minter, accounts, network, config, interface
from rich import print, pretty, print_json
from rich.console import Console
from pathlib import Path
import sys, requests, json, logging, os, io
import ipfsApi 
from dotenv import load_dotenv, find_dotenv
from asgiref.sync import async_to_sync, sync_to_async
console = Console()

@sync_to_async
def get_metadata_form():
    metadata_schema =\
    {
        "title": "DALL-E art",
        "type": "AI illusions",
        "properties": {
            "name": {
                "type": "string",
                "description": "Identifies the asset to which this NFT represents"
            },
            "description": {
                "type": "string",
                "description": "Describes the asset to which this NFT represents"
            },
            "image": {
                "type": "string",
                "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
            }
        }
    }
    return json.dumps(metadata_schema)

@async_to_sync
def generate_metadata_based_on_picture_minted(data):
    pass

@async_to_sync
async def adding_to_ipfs(token_id:int, image_path:str) -> str:
    try:
        ipfs = await ipfsApi.Client("127.0.0.1",port=5001)
    except Exception as err:
        logging.warning("The IPFS could't connect")
        return False
    
    if not os.path.isdir(image_path) or\
        image_path.split("/")[-1].split(".")[-1] not in ["png","jpg","jpeg"]:
            logging.warning(f"The directory or file type is not valid")
            return False
    
    file_name = image_path.split("/")[-1]

    with Path(image_path).open("rb") as file:
        ipfs_add = ipfs.add(file.read())

    ipfs_hash = ipfs_add[0].get("Hash")
    token_uri = f"https://ipfs.io/ipfs/{ipfs_hash}?filename={file_name}"
    return token_uri


@async_to_sync
async def adding_to_pinada(CID, metadata:str):
    if len(CID) != 46: return False
    if CID[:3] != "Qmb": return "invalid CID"

    load_dotenv(find_dotenv())
    pinata_api_key = os.environ.get("PINATA_API_KEY")
    pinata_api_secret_key = os.environ.get("PINATA_API_SECRET_KEY")
    pinata_jwt_key = os.environ.get("PINATA_JWY")

    metadata_schema = json.loads(get_metadata_form)
    nft_metadata = ""  # Her we will configure metadata based on the minted image extracted from DALL-E model

    pinata_url = "https://api.pinata.cloud/pinning/pinByHash"
    payload = json.dumps({
        'hashToPin' : CID,
        'pinataMetadata' : nft_metadata
    })
    headers = {
        'Authorization' : pinata_jwt_key,
        'content-Type' : 'application/json'
    }

    response = await requests.request(
        'POST', pinata_url, data=payload, headers=headers)
    
    if not response.status_code == 200: 
        logging.debug(f"The status code received from pinata request is {response.status_code}")
        return False
    
    logging.info("IPFS CID uploaded on Pinata successfully")
    return True



