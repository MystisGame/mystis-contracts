import pytest
import asyncio

from starkware.starknet.public.abi import get_selector_from_name
from signers import MockSigner
from nile.utils import (
    assert_revert, assert_revert_entry_point
)
from convert import (
    str_to_felt, long_str_to_array
)
from utils import (
    get_contract_class, assert_event_emitted, cached_contract, State, Account
)

COLLECTION_NAME = str_to_felt('Mystis')
COLLECTION_SYMBOL = str_to_felt('Mystis')
OWNER = 0x02563F77f6d13D521C45605C2440A07Ec63471A39e7fA768abDb8Fdafbf774De
TOKEN_URI = long_str_to_array("ipfs://XXX/") # replace XXX by our gateway
TOKEN_URI_LEN = len(TOKEN_URI)
TOKEN_URI_SUFFIX = str_to_felt('.json')
MAX_SUPPLY = 8000

# random value
VALUE = 123



signer = MockSigner(123456789987654321)

@pytest.fixture(scope='module')
def contract_classes():
    # compile starknet files
    account_cls = Account.get_class
    implementation_cls = get_contract_class('MystisNFT')
    proxy_cls = get_contract_class('MystisProxy')
    
    return account_cls, implementation_cls, proxy_cls


@pytest.fixture(scope='module')
async def proxy_init(contract_classes):
    account_cls, implementation_cls, proxy_cls = contract_classes
    # Create a new StarkNet class that simulates the StarkNet system.
    starknet = await State.init()

    # Deploy the contract
    account1 = await Account.deploy(signer.public_key)
    account2 = await Account.deploy(signer.public_key)

    implementation_decl = await starknet.declare(
        contract_class=implementation_cls
    )

    selector = get_selector_from_name('initializer')
    params = [
        COLLECTION_NAME,
        COLLECTION_SYMBOL,
        OWNER,
        TOKEN_URI_LEN,
        TOKEN_URI,
        TOKEN_URI_SUFFIX,
        MAX_SUPPLY,
        account1.contract_address, # admin account
    ]

    # Deploy contract
    proxy = await starknet.deploy(
        contract_class=proxy_cls,
        constructor_calldata=[
            implementation_decl.class_hash,
            selector,
            len(params),
            *params
        ]
    )

    return starknet.state, account1, account2, proxy

@pytest.fixture
def proxy_factory(contract_classes, proxy_init):
    account_cls, _, proxy_cls = contract_classes
    state, account1, account2, proxy = proxy_init

    _state = state.copy()
    
    admin = cached_contract(_state, account_cls, account1)
    other = cached_contract(_state, account_cls, account2)
    proxy = cached_contract(_state, proxy_cls, proxy)

    return admin, other, proxy

#
# initializer
#

@pytest.mark.asyncio
async def test_initializer(proxy_factory):
    admin, _, proxy = proxy_factory

    # check admin is set
    execution_info = await signer.send_transaction(
        admin, proxy.contract_address, 'getAdmin', []
    )
    assert execution_info.call_info.retdata[1] == admin.contract_address

@pytest.mark.asyncio
async def test_initializer_after_initialized(proxy_factory):
    admin, _, proxy = proxy_factory

    await assert_revert(signer.send_transaction(
        admin, proxy.contract_address, 'initializer', [admin.contract_address]),
        reverted_with="Proxy: contract already initialized"
    )

#
# set_admin
#

@pytest.mark.asyncio
async def test_set_admin(proxy_factory):
    admin, _, proxy = proxy_factory

    # set admin
    tx_exec_info = await signer.send_transaction(
        admin, proxy.contract_address, 'setAdmin', [VALUE]
    )

    # check event
    assert_event_emitted(
        tx_exec_info,
        from_address=proxy.contract_address,
        name='AdminChanged',
        data=[
            admin.contract_address,       # old admin
            VALUE                         # new admin
        ]
    )

    # check new admin
    execution_info = await signer.send_transaction(
        admin, proxy.contract_address, 'getAdmin', []
    )
    assert execution_info.call_info.retdata[1] == VALUE


@pytest.mark.asyncio
async def test_set_admin_from_unauthorized(proxy_factory):
    _, non_admin, proxy = proxy_factory

    # set admin
    await assert_revert(signer.send_transaction(
        non_admin, proxy.contract_address, 'setAdmin', [VALUE]),
        reverted_with="Proxy: caller is not admin"
    )

#
# fallaback
#

@pytest.mark.asyncio
async def test_fallback_when_selector_does_not_exist(proxy_factory):
    admin, _, proxy = proxy_factory

    # should fail with entry point error
    await assert_revert_entry_point(
        signer.send_transaction(
            admin, proxy.contract_address, 'invalid_selector', []
        ),
        invalid_selector='invalid_selector'
    )