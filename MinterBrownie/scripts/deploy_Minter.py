from ast import expr_context
from importlib.metadata import metadata
from telnetlib import STATUS
from scripts.complement_scripts import get_metadata_form, adding_to_ipfs_and_get_tokenURI, adding_to_pinata
from brownie import Minter, accounts, config, network
from rich import print, pretty, print_json
from rich.console import Console
import sys, requests, logging, argparse,json
from asgiref.sync import sync_to_async
import playsound
console = Console()

def main():
    logging.basicConfig(filename="debug.log", level=logging.DEBUG)  
    logging.basicConfig(filename="deploy_data.log", level=logging.INFO)
    try:
        developer_account = accounts.add(
            config.get("wallets",{}).get("private_key"))
    except Exception as err:
        logging.warning("The main account couldn't implement")
    
    print(f"We are working on {network.show_active()}")
    contract_deployed = Minter.deploy("DALL-E", "dalle", {'from' : developer_account})
    logging.info(contract_deployed)

    token_id = contract_deployed.get_token_id()  
    with console.status("It's uploading..."):
        try:
            path = "./images/duck.jpg"

            sys.stdout.write("\r")
            sys.stdout.write("adding to IPFS...")
            sys.stdout.write("\r")            
            adding_to_ipfs = adding_to_ipfs_and_get_tokenURI(token_id, path)
            sys.stdout.flush()

            metadata_schema_fetched = get_metadata_form(
                "The solitude belongs success illusion", "illusion", json.loads(adding_to_ipfs).get("token_uri","")
            )

            sys.stdout.write("\r")
            sys.stdout.write("adding to Pinata...")
            sys.stdout.write("\r")
            add_to_pinata_and_get_response = adding_to_pinata(
                json.loads(adding_to_ipfs).get('cid', ''),
                metadata_schema_fetched
            )
            sys.stdout.flush()

            print_json(add_to_pinata_and_get_response)

        except Exception as err:
            logging.debug(err)
            console.log(err)