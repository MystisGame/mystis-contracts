%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.nft.IMystisNFT import IMystisNFT

const NAME = 85184023390579;
const SYMBOL = 85184023390579;
const OWNER = 123;
const BASE_URI_LEN = 2;
const BASE_URI = 123;

const BASE_URI_SUFFIX = 199354445678;
const MAX_SUPPLY = 800;
const PROXY_ADMIN = 456;

@external
func __setup__() {
    %{
        declared = declare("contracts/nft/MystisNFT.cairo")
        prepared = prepare(declared, [
            ids.NAME,
            ids.SYMBOL,
            ids.OWNER,
            ids.BASE_URI_LEN,
            ids.BASE_URI,
            ids.BASE_URI_SUFFIX,
            ids.MAX_SUPPLY,
            ids.PROXY_ADMIN,
        ])
        context.mystis_nft_address = deploy(prepared).contract_address
    %}
    return ();
}

@external
func test_mystis_nft_deploy{syscall_ptr: felt*, range_check_ptr}() {
    tempvar mystis_nft_address: felt;

    %{
        ids.mystis_nft_address = context.mystis_nft_address
    %}

    let (name) = IMystisNFT.name(contract_address=mystis_nft_address);

    assert NAME = name;

    return ();
}