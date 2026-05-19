// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AddressSet.sol";

contract Whitelist {
    using AddressSet for AddressSet.Set;

    AddressSet.Set private whitelist;

    event AddressAdded(address indexed account);
    event AddressRemoved(address indexed account);

    function addAddress(address addr) external returns (bool) {
        bool success = whitelist.add(addr);
        if (success) {
            emit AddressAdded(addr);
        }
        return success;
    }

    function removeAddress(address addr) external returns (bool) {
        bool success = whitelist.remove(addr);
        if (success) {
            emit AddressRemoved(addr);
        }
        return success;
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist.contains(addr);
    }

    function getWhitelistLength() external view returns (uint256) {
        return whitelist.length();
    }

    function getAddressAt(uint256 index) external view returns (address) {
        return whitelist.at(index);
    }

    function getAllAddresses() external view returns (address[] memory) {
        return whitelist.getAddresses();
    }
}