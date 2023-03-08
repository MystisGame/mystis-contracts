// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address 
from starkware.starknet.common.syscalls import deploy
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import FALSE

@event
func new_collection_deployed(contract_address: felt) {
}

@storage_var
func salt() -> (value: felt) {
}

@storage_var
func mystis_nft_class_hash() -> (value: felt) {
}

@storage_var
func deployed_collections(salt) -> (addresses: felt) {
}

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(mystis_nft_class_hash_: felt) {
    mystis_nft_class_hash.write(value=mystis_nft_class_hash_);
    return ();
}

@external
func deploy_collection{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    name: felt,
    symbol: felt,
    owner: felt, 
    base_token_uri_len: felt,
    base_token_uri: felt*,
    token_uri_suffix: felt,
    supply: Uint256
) -> (contract_address: felt) {
    let (current_salt) = salt.read();
    let (class_hash) = mystis_nft_class_hash.read();
    let (contract_address) = deploy(
        class_hash=class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=8,
        constructor_calldata=cast(new (
            name,
            symbol,
            owner, 
            base_token_uri_len,
            base_token_uri,
            token_uri_suffix,
            supply,
        ), felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=current_salt + 1);

    new_collection_deployed.emit(
        contract_address=contract_address
    );
    return (contract_address=contract_address);
}

