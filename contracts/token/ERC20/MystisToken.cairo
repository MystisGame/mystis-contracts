// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.library import ERC20
from openzeppelin.security.pausable.library import Pausable
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy
from contracts.oracle.IEmpiricOracle import IEmpiricOracle, GenericEntry

const EMPIRIC_ORACLE_ADDRESS = 0x446812bac98c08190dee8967180f4e3cdcd1db9373ca269904acb17f67f7093;
const SOURCE = 85046045460819; // str_to_felt("MYSTIS")

@external
func initializer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    name: felt,
    symbol: felt,
    owner: felt, 
    proxy_admin: felt
) {
    ERC20.initializer(name, symbol, 18);
    Ownable.initializer(owner);
    Proxy.initializer(proxy_admin);
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

@view
func name{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (name: felt) {
    return ERC20.name();
}

@view
func symbol{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (symbol: felt) {
    return ERC20.symbol();
}

@view
func totalSupply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (totalSupply: Uint256) {
    let (totalSupply) = ERC20.total_supply();
    return (totalSupply=totalSupply);
}

@view
func decimals{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (decimals: felt) {
    return ERC20.decimals();
}

@view
func balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(account: felt) -> (balance: Uint256) {
    return ERC20.balance_of(account);
}

@view
func allowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt, spender: felt) -> (remaining: Uint256) {
    return ERC20.allowance(owner, spender);
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

@view
func get_claimable_amount{syscall_ptr: felt*, range_check_ptr}(wallet_address: felt) -> (
    entry: GenericEntry
) {
    let (entry: GenericEntry) = IEmpiricOracle.get_generic_entry(
        EMPIRIC_ORACLE_ADDRESS, wallet_address, SOURCE
    );
    return (entry=entry);
}

//
// Externals
//

@external
func transfer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(recipient: felt, amount: Uint256) -> (success: felt) {
    Pausable.assert_not_paused();
    return ERC20.transfer(recipient, amount);
}

@external
func transferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    Pausable.assert_not_paused();
    return ERC20.transfer_from(sender, recipient, amount);
}

@external
func approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(spender: felt, amount: Uint256) -> (success: felt) {
    Pausable.assert_not_paused();
    return ERC20.approve(spender, amount);
}

@external
func increaseAllowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(spender: felt, added_value: Uint256) -> (success: felt) {
    Pausable.assert_not_paused();
    return ERC20.increase_allowance(spender, added_value);
}

@external
func decreaseAllowance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(spender: felt, subtracted_value: Uint256) -> (success: felt) {
    Pausable.assert_not_paused();
    return ERC20.decrease_allowance(spender, subtracted_value);
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
func claim{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(to: felt, amount: Uint256) {
    let (entry) = get_claimable_amount(to);
    let (amount: Uint256) = // Uint256(entry.value, 0);
    Ownable.assert_only_owner();
    ERC20._mint(to, amount);
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