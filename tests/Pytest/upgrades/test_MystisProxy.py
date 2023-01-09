"""MystisNFT system test file"""

import pytest
import asyncio
import os

from starkware.starknet.public.abi import get_selector_from_name
from signers import MockSigner
from nile.utils import (
    assert_revert, assert_revert_entry_point
)
from utils import (
    get_contract_class, cached_contract, assert_event_emitted,
    State, Account
)
from convert import (
    str_to_felt, long_str_to_array, to_uint, 
)

COLLECTION_NAME = str_to_felt('Mystis') # felt -> 85184023390579
COLLECTION_SYMBOL = str_to_felt('Mystis') # felt -> 85184023390579

# random URI
TOKEN_URI = [
    str_to_felt("https://gateway.pinata.cloud/ip"), # short strings cannot have more than 31 characters
    str_to_felt("fs/XXXXXXXXXXXXXXXXXXXXXXXXXXX/")
]

TOKEN_URI_LEN = len(TOKEN_URI)
TOKEN_URI_SUFFIX = str_to_felt('.json') # felt -> 199354445678
MAX_SUPPLY = to_uint(5555)

signer = MockSigner(12345678987654321)

@pytest.fixture(scope='module')
def contract_classes():
    account_cls = Account.get_class
    mystis_nft_cls = get_contract_class('MystisNFT')
    mystis_proxy_cls = get_contract_class('MystisProxy')

    return account_cls, mystis_nft_cls, mystis_proxy_cls

@pytest.fixture(scope='module')
async def proxy_init(contract_classes):
    account_cls, mystis_nft_cls, mystis_proxy_cls = contract_classes
    starknet = await State.init()
    account1 = await Account.deploy(signer.public_key)
    account2 = await Account.deploy(signer.public_key)
    mystis_decl = await starknet.declare(
        contract_class=mystis_nft_cls
    )
    selector = get_selector_from_name('initializer')
    params = [
        COLLECTION_NAME,            # name
        COLLECTION_SYMBOL,          # symbol
        account1.contract_address,  # collection owner
        TOKEN_URI_LEN,              # length token uri
        *TOKEN_URI,                 # base token uri
        TOKEN_URI_SUFFIX,           # base token suffix
        *MAX_SUPPLY,                # initial supply
        account1.contract_address   # proxy admin
    ]
    proxy = await starknet.deploy(
        contract_class=mystis_proxy_cls,
        constructor_calldata=[
            mystis_decl.class_hash,
            selector,
            #len(params),
            #*params
            params,
        ]
    )
    return (starknet.state, account1, account2, proxy)

@pytest.fixture
def proxy_factory(contract_classes, proxy_init):
    account_cls, _, mystis_proxy_cls = contract_classes
    state, account1, account2, proxy = proxy_init
    _state = state.copy()

    admin = cached_contract(_state, account_cls, account1)
    other = cached_contract(_state, account_cls, account2)
    proxy = cached_contract(_state, mystis_proxy_cls, proxy)

    return admin, other, proxy

@pytest.mark.asyncio
async def test_initializer(proxy_factory):
    admin, _, proxy = proxy_factory

    # check admin is set
    execution_info = await signer.send_transaction(
        admin, proxy.contract_address, 'getAdmin', []
    )
    assert execution_info.call_info.retdata[1] == admin.contract_address