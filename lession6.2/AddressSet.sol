// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 地址白名单库（EnumerableSet模式）
library AddressSet {
    struct Set {
        address[] addresses;
        mapping(address => uint256) indexOf;
        mapping(address => bool) contains;
    }

    // 添加地址
    function add(Set storage set, address addr) internal returns (bool) {
        if (set.contains[addr]) {
            return false;
        }
        set.contains[addr] = true;
        set.indexOf[addr] = set.addresses.length;
        set.addresses.push(addr);
        return true;
    }

    // 移除地址
    function remove(Set storage set, address addr) internal returns (bool) {
        if (!set.contains[addr]) {
            return false;
        }

        delete set.contains[addr];

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

    // 检查是否包含地址
    function contains(Set storage set, address addr) internal view returns (bool) {
        return set.contains[addr];
    }

    // 获取集合大小
    function length(Set storage set) internal view returns (uint256) {
        return set.addresses.length;
    }

    // 根据索引获取地址
    function at(Set storage set, uint256 index) internal view returns (address) {
        require(index < set.addresses.length, "Index out of bounds");
        return set.addresses[index];
    }

    // 获取所有地址（完整数组）
    function getAddresses(Set storage set) internal view returns (address[] memory) {
        return set.addresses;
    }
}