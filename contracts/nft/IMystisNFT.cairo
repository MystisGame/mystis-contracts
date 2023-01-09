// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMystisNFT {
    func totalMintedHeroes() -> (supply: Uint256) {
    }

    func owner() -> (owner: felt) {
    }

    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func maxSupply() -> (supply: Uint256) {
    }

    func tokenURI(token_id: Uint256) -> (token_uri_len: felt, token_uri: felt*) {
    }

    func ownerOf(token_id: Uint256) -> (owner: felt) {
    }
}