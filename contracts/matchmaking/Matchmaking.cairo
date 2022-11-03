%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_block_number

from contracts.matchmaking.library import Matchmaking

// 
// Getters
//

@view
func retrieveOpponent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (word: felt) {
    let (_word) = Matchmaking.retrieveOpponent();
    return (_word,);
}

// 
// Externals
//

@external
func requestRandomOpponent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    seed: felt, 
    callback_address: felt, 
    callback_gas_limit: felt, 
    publish_delay: felt, 
    num_words: felt
) -> (request_id: felt) {
    return Matchmaking.requestRandomOpponent(seed, callback_address, callback_gas_limit, publish_delay, num_words);
}

@external
func opponentFound{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    requestor_address: felt,
    request_id: felt,
    random_words_len: felt,
    random_words: felt*,
) -> () {
    return Matchmaking.opponentFound(requestor_address, request_id, random_words_len, random_words);
}

@external
func startFight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    return Matchmaking.startFight();  
}

@external
func claimRewards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    return Matchmaking.claimRewards();
}