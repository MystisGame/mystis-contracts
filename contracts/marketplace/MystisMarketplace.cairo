// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.security.pausable.library import Pausable
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.upgrades.library import Proxy

@event
func new_nft_sale(ticket_id: Uint256, start_price: Uint256, end_sale_date: Uint256) {
}

@event
func offer_added(ticket_id: Uint256, bidder: felt, amount: Uint256) {
}

@event
func bidder_refunded(ticket_id: Uint256, bidder: felt, amount: Uint256) {
}

@event
func update_nft_sale(ticket_id: Uint256, start_price: Uint256) {
}


struct NftOffer {
    owner: felt,
    start_price: Uint256,    
    end_sale_date: felt,
    highest_bidder: felt,
    highest_bid: Uint256,
    active: felt,
}

@storage_var
func nft_offers(nft_id: Uint256) -> (nft_offer: NftOffer) {
}

@storage_var
func fees() -> (listing_fees: Uint256) {
}

@external
func initializer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    owner: felt, 
    listing_fees: Uint256,
    proxy_admin: felt,
) {
    Ownable.initializer(owner);
    Proxy.initializer(proxy_admin);
    fees.write(listing_fees);

    return ();
}

//
// Getters
//

@view
func getImplementationHash{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}() -> (
    implementation: felt
) {
    return Proxy.get_implementation_hash();
}

@view
func getAdmin{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}() -> (admin: felt) {
    return Proxy.get_admin();
}

//
// Internals
//

func _refund{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    ticket_id: Uint256,
    bidder: felt,
    amount: Uint256
) {
    
    return ();
}

//
// Externals
//

@external
func create_nft_sale{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    ticket_id: Uint256, 
    start_price: Uint256, 
    end_sale_date: Uint256
) {
    
    return ();
}

@external
func add_offer_on_nft{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    ticket_id: Uint256
) {
    
    return ();
}

@external
func cancel_offer_on_nft{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    ticket_id: Uint256
) {
    
    return ();
}

@external
func claim{
    syscall_ptr: felt*, 
    pedersen_ptr: HashBuiltin*, 
    range_check_ptr
}(
    ticket_id: Uint256
) {
    
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
    return ();
}

@external
func setAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_admin: felt) {
    Proxy.assert_only_admin();
    Proxy._set_admin(new_admin);
    return ();
}