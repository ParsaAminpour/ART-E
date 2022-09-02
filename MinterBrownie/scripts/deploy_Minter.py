from brownie import Minter, accounts, config, network
from rich import print, pretty, print_json
from rich.console import Console
import sys, requests, logging, argparse
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
    
    contract_deployed = Minter.deploy({'from' : developer_account})
    for account in accounts:
        console.log(f"{account.address} : {network.show_active()}")


# adding to IPFS and get TokenURI
# adding to Pianda and retrive it
# create base of Metadata
# config metadata with sample image
# generate opensea url for accessing to the collection url on opensea (rinkeby Testnetwork)
    