%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_block_number

from contracts.randomness.IRandomness import IRandomness

const EMPIRIC_RANDOM_ORACLE_ADDRESS = 0x681a206bfb74aa7436b3c5c20d7c9242bc41bc6471365ca9404e738ca8f1f3b;

@storage_var
func Matchmaking__random_id() -> (random_word: felt) {
}

namespace Matchmaking {
    // *
    // * retrieveOpponent
    // *
    // * Retrieve the opponent of the sender address.
    // *
    // * Output :
    // * opponent_address: address of the sender's opponent.
    // *
    func retrieveOpponent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (word: felt) {
        let (_word) = Matchmaking__random_id.read();
        return (_word,);
    }
    
    // *
    // * requestRandomOpponent
    // *
    // * Allows the smart-contract to request randomness from Empiric Network.
    // * We specify an uniquely seed to determines the randomness, so Empiric as the VRF provider is
    // * not able to manipulate the randomness. As the required private key is not know the smart-contract
    // * is not able to predict the randomness that is calculated off-chain and sent on-chain with the proof.
    // * Until it it possible to get the block_hash on StarkNet, we will use `hash2(request_address, hash(nonce, block_timestamp))`
    // * Inputs :
    // * seed: random seed that feeds into the verifiable random algorithm, must be different every time.
    // * 
    // * callback_address: address to call receive_random_words on with the randomness.
    // * callback_gas_limit: gas limit on the callback function.
    // * publish_delay: minimum number of blocks to wait from the request to fulfillment.
    // * num_words: number of random words to receive in one call.
    // *
    // * Output :
    // * request_id: ID of the request, which can be used to check the status, cancel the request 
    // * and check that the callback function was correctly called.
    // *
    func requestRandomOpponent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        seed: felt, 
        callback_address: felt, 
        callback_gas_limit: felt, 
        publish_delay: felt, 
        num_words: felt
    ) -> (request_id: felt) {
        let request_id = IRandomness.request_random(
            EMPIRIC_RANDOM_ORACLE_ADDRESS,
            seed, 
            callback_address, 
            callback_gas_limit, 
            publish_delay, 
            num_words
        );
        return (request_id);
    }

    // *
    // * opponentFound
    // *
    // * Allows the smart-contract to receive generated random word.
    // *
    // * Inputs :
    // * requestor_address: address that submitted the randomness request.
    // * request_id: id of the randomness request (auto-incrementing for each requestor_address).
    // * random_words_len: number of random words returned.
    // * random_words: pointer to the first random word.
    // *
    func opponentFound{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        requestor_address: felt,
        request_id: felt,
        random_words_len: felt,
        random_words: felt*,
    ) -> () {
        // Have to make sure that the caller is the Empiric Randomness Oracle contract
        let (caller_address) = get_caller_address();
        assert EMPIRIC_RANDOM_ORACLE_ADDRESS = caller_address;

        // Verify that we only received one random word
        assert random_words_len = 1;
        // Checking that the requestor is the contract itself
        let (contract_address) = get_contract_address();
        assert requestor_address = contract_address;

        // Make sure that request_id is the same as requestRandomOpponent request_id

        // Use modulo to have an id in range of [0, mintedHeroes - 1] >>> `IMystisNFT.mintedHeroes() -> (supply)`
        let random_word = random_words[0];
        // Get owner address of hero with previous id >>> `IMystisNFT.ownerOf(random_id) -> (address)`
        // Store opponent address with sender address
        Matchmaking__random_id.write(random_word);
        // Start fighting session (Off-chain)

        return ();
    }

    // *
    // * startFight
    // *
    // * Alterne between attack from sender player and attack from opponent
    // *
    func startFight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        
    ) {
        // Think about fighting process (auto-battler)
        // If one Heros is dead call `_end()`
        return ();  
    }

    // *
    // * claimRewards
    // *
    // * At the end of each fight, an amount of $WAR tokens is automatically sent to the fighters' wallet. 
    // *
    func claimRewards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        
    ) {
        // Call `_calculateRewardsAmount()`
        return ();
    }
}

func _fightingSession{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    
) {
    return ();
}

func _endFight{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    
) {
    // Record the game result inside of `Elo.recordResult()`
    // Store both opponents, result
    // Increase winning / losing
    // Call `claimRewards()`

    return ();  
} 


func _calculateRewardsAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    
) {
    // Define how the $WAR token amount is calculated
    return ();
}
