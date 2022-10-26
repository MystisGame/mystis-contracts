// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address 
from starkware.cairo.common.uint256 import Uint256, uint256_add

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.pausable.library import Pausable
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy

from contracts.libraries.ERC721_Metadata_base (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)

@storage_var
func counter_nft() -> (token_id: felt) {
}

@external
func initializer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
}(
    name: felt,
    symbol: felt,
    owner: felt, 
    base_token_uri_len: felt,
    base_token_uri: felt,
    token_uri_suffix: felt,
    proxy_admin: felt
) {
    ERC721.initializer(name, symbol);
    ERC721_Metadata_initializer();
    Ownable.initializer(owner);
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);
    counter.write(Uint256(1, 0));
    Proxy.initializer(proxy_admin);
    return ();
}

//
// Getters
//

@view
func tokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*) {
    let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id);
    return (token_uri_len, token_uri);
}

@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(interfaceId: felt) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func name{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (name: felt) {
    return ERC721.name();
}

@view
func symbol{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (symbol: felt) {
    return ERC721.symbol();
}

@view
func balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt) -> (balance: Uint256) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: Uint256) -> (owner: felt) {
    return ERC721.owner_of(token_id);
}

@view
func getApproved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: Uint256) -> (approved: felt) {
    return ERC721.get_approved(token_id);
}

@view
func isApprovedForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt, operator: felt) -> (isApproved: felt) {
    let (isApproved) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func paused{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (paused: felt) {
    return Pausable.is_paused();
}

@view
func owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (owner: felt) {
    return Ownable.owner();
}

//
// Externals
//

@external
func mint{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}() {
    let (caller_address) = get_caller_address();
    let (token_id: Uint256) = counter_nft.read();
    ERC721._mint(caller_address, token_id);
    let (res, _) = uint256_add(token_id, Uint256(1, 0));
    counter_nft.write(res);
}

@external
func setTokenURI{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    base_token_uri_len: felt, base_token_uri: felt*, token_uri_suffix: felt
) {
    Ownable.assert_only_owner();
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);
}

@external
func approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(to: felt, tokenId: Uint256) {
    Pausable.assert_not_paused();
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(operator: felt, approved: felt) {
    Pausable.assert_not_paused();
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256) {
    Pausable.assert_not_paused();
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    Pausable.assert_not_paused();
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func transferOwnership{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(newOwner: felt) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() {
    Ownable.renounce_ownership();
    return ();
}

@external
func pause{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() {
    Ownable.assert_only_owner();
    Pausable._pause();
    return ();
}

@external
func unpause{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() {
    Ownable.assert_only_owner();
    Pausable._unpause();
    return ();
}

@external
func burn{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) {
    Pausable.assert_not_paused();
    ERC721.assert_only_token_owner(tokenId);
    ERC721._burn(tokenId);
    return ();
}

@external
func upgrade{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_implementation: felt) -> () {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    Proxy.Upgraded(new_implementation);
    return ();
}