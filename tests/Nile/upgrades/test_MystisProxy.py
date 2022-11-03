"""MystisNFT system test file"""
import pytest
import asyncio
import os

from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starkware_utils.error_handling import StarkException
from tests.Nile.utils.TransactionSender import (
    TransactionSender,
    from_call_to_call_array,
)

from tests.Nile.utils.Signer import Signer
from tests.Nile.utils.utilities import str_to_felt, to_uint, long_str_to_array

COLLECTION_NAME = str_to_felt('Mystis')
COLLECTION_SYMBOL = str_to_felt('Mystis')
OWNER = 0x02563F77f6d13D521C45605C2440A07Ec63471A39e7fA768abDb8Fdafbf774De
TOKEN_URI = long_str_to_array("ipfs://XXX/") # replace XXX by our gateway
TOKEN_URI_LEN = len(TOKEN_URI)
TOKEN_URI_SUFFIX = str_to_felt('.json')
MAX_SUPPLY = 8000

MYSTIS_NFT = os.path.join('contracts/nft','MystisNFT.cairo')
MYSTIS_PROXY = os.path.join('contracts/proxy','MystisProxy.cairo')

signer1 = Signer(12345678987654321)
signer2 = Signer(987654321123456789)

