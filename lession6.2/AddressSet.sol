// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressSet {
    struct Set {
        address[] addresses;
        mapping(address => uint256) indexOf;
        mapping(address => bool) isIncluded;
    }

    function add(Set storage set, address addr) internal returns (bool) {
        if (set.isIncluded[addr]) {
            return false;
        }
        set.isIncluded[addr] = true;
        set.indexOf[addr] = set.addresses.length;
        set.addresses.push(addr);
        return true;
    }

    function remove(Set storage set, address addr) internal returns (bool) {
        if (!set.isIncluded[addr]) {
            return false;
        }

        delete set.isIncluded[addr];

        uint256 index = set.indexOf[addr];
        uint256 lastIndex = set.addresses.length - 1;

        if (index != lastIndex) {
            address lastAddr = set.addresses[lastIndex];
            set.addresses[index] = lastAddr;
            set.indexOf[lastAddr] = index;
        }

        set.addresses.pop();
        delete set.indexOf[addr];
        return true;
    }

    function contains(Set storage set, address addr) internal view returns (bool) {
        return set.isIncluded[addr];
    }

    function length(Set storage set) internal view returns (uint256) {
        return set.addresses.length;
    }

    function at(Set storage set, uint256 index) internal view returns (address) {
        require(index < set.addresses.length, "Index out of bounds");
        return set.addresses[index];
    }

    function getAddresses(Set storage set) internal view returns (address[] memory) {
        return set.addresses;
    }
}