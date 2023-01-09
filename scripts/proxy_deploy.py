import asyncio
import json

from starknet_py.contract import Contract
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.networks import TESTNET

# Local network
from starknet_py.net.models import StarknetChainId
from starknet_py.transactions.declare import make_declare_tx
from starkware.starknet.compiler.compile import get_selector_from_name

from utils import str_to_felt, long_str_to_array, decimal_to_hex, to_uint, hex_to_felt

ADDRESS = "0x63533ce1eeabcd4fe1ad85eee3c372a2e4a3e6fe3e0c7cb2cc52f784c847f17"
PRIVATE_KEY = 0xb11149afa12f770443c653c1ecb3583a
PUBLIC_KEY = 0x4c2308a08b95afbff4d960c6e53c54c3a1ffd0c07a08f39fe8aaf47b628d95c

OWNER = 0x63533ce1eeabcd4fe1ad85eee3c372a2e4a3e6fe3e0c7cb2cc52f784c847f17

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
    network = GatewayClient("http://localhost:5050")
    account = AccountClient(
        client=network, 
        address=ADDRESS,
        key_pair=KeyPair(private_key=PRIVATE_KEY, public_key=PUBLIC_KEY),
        chain=StarknetChainId.TESTNET,
        supported_tx_version=1, # (__validate__ function)
    )
    print("✅ Account instance on TESTNET has been created")
    # Deploy an account on TESTNET and returns an instance
    return network, account

async def declare_contract(account, contract_src):
    declare_tx = make_declare_tx(compilation_source=[contract_src])
    return await account.declare(declare_tx)

async def setup_contracts(network, account):
    # Declare implementation contract
    print("⏳ Declaring MystisNFT Contract...")
    declare_result = await declare_contract(account, "contracts/nft/MystisNFT.cairo")
    print("✅ MystisNFT Contract has been declared")
    selector = get_selector_from_name("initializer")
    mystis_nft_constructor_args = [
        COLLECTION_NAME,                # name
        COLLECTION_SYMBOL,              # symbol
        OWNER,                          # collection owner
        TOKEN_URI_LEN,                  # length token uri
        *TOKEN_URI,                     # base token uri
        TOKEN_URI_SUFFIX,               # base token suffix
        *MAX_SUPPLY,                    # initial supply
        account.address                 # proxy admin
    ]
    print("⏳ Declaring Proxy Contract...")
    proxy_declare_tx = await account.sign_declare_transaction(
        compilation_source=["contracts/proxy/MystisProxy.cairo"], 
        max_fee=int(1e16)
    )
    resp = await account.declare(transaction=proxy_declare_tx)
    await account.wait_for_tx(resp.transaction_hash)
    print("✅ Proxy Contract has been declared")

    # Redefine the ABI so that `call` and `invoke` work
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
    # Redefine the ABI so that `call` and `invoke` work
    with open("artifacts/abis/MystisNFT.json", "r") as abi_file:
        implementation_abi = json.load(abi_file)

    proxy = Contract(
        address=proxy.address,
        abi=implementation_abi,
        client=account
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
    network, account = await setup_accounts()
    proxy_contract = await setup_contracts(network, account)

    print("⏳ Calling `getAdmin` function...")
    (proxy_admin,) = await proxy_contract.functions["getAdmin"].call()
    assert account.address == proxy_admin
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