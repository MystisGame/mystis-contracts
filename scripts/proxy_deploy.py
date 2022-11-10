import asyncio
import json

from starknet_py.contract import Contract
from starknet_py.net import AccountClient
from starknet_py.net.full_node_client import FullNodeClient
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.networks import TESTNET

# Local network
from starknet_py.net.models import StarknetChainId
from starknet_py.transactions.declare import make_declare_tx
from starkware.starknet.compiler.compile import get_selector_from_name

from utils import str_to_felt, long_str_to_array, decimal_to_hex, to_uint, hex_to_felt

OWNER = 0x02563F77f6d13D521C45605C2440A07Ec63471A39e7fA768abDb8Fdafbf774De

COLLECTION_NAME = str_to_felt('Mystis')
COLLECTION_SYMBOL = str_to_felt('Mystis')

TOKEN_URI = [
    str_to_felt("https://gateway.pinata.cloud/ip"), # short strings cannot have more than 31 characters
    str_to_felt("fs/XXXXXXXXXXXXXXXXXXXXXXXXXXX/")
]
TOKEN_URI_LEN = len(TOKEN_URI)
TOKEN_URI_SUFFIX = str_to_felt('.json')

MAX_SUPPLY = to_uint(800)

async def setup_accounts():
    # Creates an account on TESTNET and returns an instance
    client = GatewayClient(net=TESTNET)
    print("⏳ Creating account on TESTNET...")
    acc_client = await AccountClient.create_account(
        client=client, chain=StarknetChainId.TESTNET
    )
    # Deploys an account on TESTNET and returns an instance
    return client, acc_client

async def declare_contract(admin_client, contract_src):
    declare_tx = make_declare_tx(compilation_source=[contract_src])
    return await admin_client.declare(declare_tx)

async def setup_contracts(network_client, admin_client):
    # Declare implementation contract
    print("⏳ Declare MystisNFT Contract...")
    declaration_result = await declare_contract(
        admin_client, "contracts/nft/MystisNFT.cairo"
    )

    selector = get_selector_from_name("initializer")
    mystis_nft_constructor_args = [
        COLLECTION_NAME,            # name
        COLLECTION_SYMBOL,          # symbol
        OWNER,                      # collection owner
        TOKEN_URI_LEN,              # length token uri
        *TOKEN_URI,                 # base token uri
        TOKEN_URI_SUFFIX,           # base token suffix
        *MAX_SUPPLY,                # initial supply
        admin_client.contract_address   # proxy admin
    ]
    # Deploy proxy and call initializer in the constructor
    deployment_result = await Contract.deploy(
        client=network_client,
        compilation_source=["contracts/proxy/MystisProxy.cairo"],
        constructor_args=[
            declaration_result.class_hash,
            selector,
            len(mystis_nft_constructor_args)
            *mystis_nft_constructor_args,
        ],
    )
    print(f'✨ Contract deployed at {decimal_to_hex(deployment_result.deployed_contract.address)}')
    # Wait for the transaction to be accepted
    await deployment_result.wait_for_acceptance()
    proxy = deployment_result.deployed_contract

    # Redefine the ABI so that `call` and `invoke` work
    with open("artifacts/abis/MystisNFT.json", "r") as abi_file:
        implementation_abi = json.load(abi_file)

    proxy = Contract(
        address=proxy.address,
        abi=implementation_abi,
        client=admin_client,
    )
    return proxy

async def upgrade_proxy(admin_client, proxy_contract, new_contract_src):
    # Declare implementation contract
    declaration_result = await declare_contract(admin_client, new_contract_src)

    # Upgrade contract
    call = proxy_contract.functions["upgrade"].prepare(
        new_implementation=declaration_result.class_hash
    )
    await admin_client.execute(calls=call, max_fee=0)
    # If you change the ABI, update the `proxy_contract` here.

async def main():
    client, acc_client = await setup_accounts()
    proxy_contract = await setup_contracts(client, acc_client)

    print("⏳ Calling `getAdmin` function...")
    (proxy_admin,) = await proxy_contract.functions["getAdmin"].call()
    assert acc_client.address == proxy_admin
    print("The proxy admin was set to our account:", hex(proxy_admin))

    # Note that max_fee=0 is only possible on starknet-devnet.
    # When deploying on testnet, your acc_client needs to have enough funds.
    value_target = 1
    print("⏳ Invoke `mint` function...")
    await proxy_contract.functions["mint"].invoke(max_fee=0)
    print("⏳ Calling `totalMintedHeroes` function...")
    (supply,) = await proxy_contract.functions["totalMintedHeroes"].call()
    assert value_target == supply
    print("✅ The proxy works!")

if __name__ == "__main__":
    asyncio.run(main())