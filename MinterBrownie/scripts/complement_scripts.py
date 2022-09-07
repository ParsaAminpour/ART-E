from brownie import Minter, accounts, network, config, interface
from requests.exceptions import ConnectionError, Timeout
from rich import print, pretty, print_json
from rich.console import Console
from pathlib import Path
import sys, requests, json, logging, os, io
import ipfsApi 
from textblob import TextBlob 
from dotenv import load_dotenv, find_dotenv
from asgiref.sync import async_to_sync, sync_to_async
console = Console()


def get_metadata_form(
    description:str, name:str, ipfs_uri:str
):
    if len(description) == 0 or len(name) == 0:
        raise ValueError("The name or description content is empty")
    
    if not ipfs_uri.startswith("https://") or len(ipfs_uri) == 0:
        raise ValueError("The IPFS URI is invalid or empty")

    blob = TextBlob(description)
    metadata_schema =\
    {
        "title": "DALL-E art",
        "description": description,
        "image" : ipfs_uri,
        "attributes" : [
            {"trait_type" : "polarity", 
                "value" : str(blob.sentiment.polarity)},
            {'trait_type' : "subjectivity",
                "value" : str(blob.sentiment.subjectivity)}
        ]
    }
    return json.dumps(metadata_schema)


@async_to_sync
async def adding_to_ipfs_and_get_tokenURI(token_id:int, image_path:str) -> str:
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
    return json.dumps({'cid' : ipfs_hash, 'token_uri' : token_uri})


@async_to_sync
async def adding_to_pinata(CID, metadata:str):
    if CID[:2] != "Qm" or len(CID) != 46: 
        raise ValueError("invalid CID")

    load_dotenv(find_dotenv())
    PINATA_API_KEY = os.environ.get("PINATA_API_KEY")
    PINATA_API_SECRET_KEY = os.environ.get("PINATA_API_SECRET_KEY")
    PINATA_JWT_KEY = os.environ.get("PINATA_JWY")

    metadata_schema = json.loads(metadata)

    pinata_url = "https://api.pinata.cloud/pinning/pinByHash"
    payload = json.dumps({
        'hashToPin' : CID,
        "pinataMetadata": {
            "name": metadata_schema.get("title"),
            "keyvalues": {
                "description": metadata_schema.get("description"),
                "image": metadata_schema.get("image"),
                'attributes' : metadata_schema.get("attributes")
            }
        }       
  })

    headers = {
        'pinata_api_key' : PINATA_API_KEY,
        'pinata_secret_api_key' : PINATA_API_SECRET_KEY,
        'Content-Type' : 'application/json'
    }

    try:
        response = await requests.request(
            'POST', pinata_url, data=payload, headers=headers)
    except (ConnectionError, Timeout, Exception) as err : return err

    if not response.status_code == 200: 
        logging.debug(f"The status code received from pinata request is {response.status_code}")
        return False
    
    logging.info(f"IPFS CID {CID} uploaded on Pinata successfully")
    return response.json()



