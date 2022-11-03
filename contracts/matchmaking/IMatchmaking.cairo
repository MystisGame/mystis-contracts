%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMatchmaking {
    func retrieveOpponent(
    ) -> (word: felt) {
    }

    func requestRandomOpponent(seed, callback_address, callback_gas_limit, publish_delay, num_words) -> (
        request_id: felt
    ) {
    }

    func opponentFound(requestor_address, request_id, random_words_len, random_words: felt*) {
    }
}