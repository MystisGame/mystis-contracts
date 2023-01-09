import asyncio
import json

from sys import argv
from starknet_py.contract import Contract
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.networks import TESTNET


# Local network
from starknet_py.net.models import StarknetChainId
from starknet_py.transactions.declare import make_declare_tx
from starkware.starknet.compiler.compile import get_selector_from_name

from utils import str_to_felt, decimal_to_hex, to_uint

ADDRESS = "0x1234"
PUBLIC_KEY = 0x4321
PRIVATE_KEY = 0x123456789

OWNER = 0x1234

COLLECTION_NAME = str_to_felt('Mystis')
COLLECTION_SYMBOL = str_to_felt('Mystis')

TOKEN_URI = [
    str_to_felt("https://gateway.pinata.cloud/ip"),
    str_to_felt("fs/XXXXXXXXXXXXXXXXXXXXXXXXXXX/")
]
TOKEN_URI_LEN = len(TOKEN_URI)
TOKEN_URI_SUFFIX = str_to_felt('.json')

MAX_SUPPLY = to_uint(800)

async def setup_accounts():
    network = GatewayClient(TESTNET)
    account = AccountClient(
        client=network, 
        address=ADDRESS,
        key_pair=KeyPair(private_key=PRIVATE_KEY, public_key=PUBLIC_KEY),
        chain=StarknetChainId.TESTNET,
        supported_tx_version=1,
    )
    print("✅ Account instance on TESTNET has been created")
    return network, account

async def declare_contract(account, contract_src):
    declare_tx = make_declare_tx(compilation_source=[contract_src])
    return await account.declare(declare_tx)

async def setup_contracts(network, account):
    print("⏳ Declaring MystisNFT Contract...")
    declare_result = await declare_contract(account, "contracts/nft/MystisNFT.cairo")
    print("✅ MystisNFT Contract has been declared")
    selector = get_selector_from_name("initializer")
    mystis_nft_constructor_args = [
        COLLECTION_NAME,
        COLLECTION_SYMBOL,
        OWNER,
        TOKEN_URI_LEN,
        *TOKEN_URI,
        TOKEN_URI_SUFFIX,
        *MAX_SUPPLY,
        account.address
    ]
    print("⏳ Declaring Proxy Contract...")
    proxy_declare_tx = await account.sign_declare_transaction(
        compilation_source=["contracts/proxy/MystisProxy.cairo"], 
        max_fee=int(1e16)
    )
    resp = await account.declare(transaction=proxy_declare_tx)
    await account.wait_for_tx(resp.transaction_hash)
    print("✅ Proxy Contract has been declared")

    with open("artifacts/abis/MystisProxy.json", "r") as proxy_abi_file:
        proxy_abi = json.load(proxy_abi_file)

    deployment_result = await Contract.deploy_contract(
        account=account,
        class_hash=resp.class_hash,
        abi=proxy_abi,
        constructor_args=[
            declare_result.class_hash,
            selector,
            mystis_nft_constructor_args,
        ],
        max_fee=int(1e16),
    )
    print(f'✨ Contract deployed at {decimal_to_hex(deployment_result.deployed_contract.address)}')
    await deployment_result.wait_for_acceptance()
    proxy = deployment_result.deployed_contract
    with open("artifacts/abis/MystisNFT.json", "r") as abi_file:
        implementation_abi = json.load(abi_file)

    proxy = Contract(
        address=proxy.address,
        abi=implementation_abi,
        client=account
    )
    return proxy

async def upgrade_proxy(admin_client, proxy_contract, new_contract_src):
    declaration_result = await declare_contract(admin_client, new_contract_src)

    call = proxy_contract.functions["upgrade"].prepare(
        new_implementation=declaration_result.class_hash
    )
    await admin_client.execute(calls=call, max_fee=int(1e16))

async def main():
    network, account = await setup_accounts()
    proxy_contract = await setup_contracts(network, account)

    print("⏳ Calling `getAdmin` function...")
    (proxy_admin,) = await proxy_contract.functions["getAdmin"].call()
    assert account.address == proxy_admin
    print("The proxy admin was set to our account:", hex(proxy_admin))

if __name__ == "__main__":
    asyncio.run(main())