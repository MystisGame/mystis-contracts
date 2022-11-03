// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMystisNFT {
    func totalMintedHeroes() -> (supply: Uint256) {
    }

    func maxSupply() -> (supply: Uint256) {
    }

    func ownerOf(token_id: Uint256) -> (owner: felt) {
    }
}