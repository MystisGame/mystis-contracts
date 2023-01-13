// SPDX-License-Identifier: MIT

%lang starknet

struct BaseEntry {
    timestamp: felt,
    source: felt,
    publisher: felt,
}

struct GenericEntry {
    base: BaseEntry,
    key: felt,
    value: felt,
}

@contract_interface
namespace IEmpiricOracle {
    func get_generic_entry(key: felt, source) -> (entry: GenericEntry) {
    }
}