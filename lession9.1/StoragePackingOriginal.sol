// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 原始版本 - 未优化
contract StoragePackingOriginal {
    uint256 public value1;
    bool public flag1;
    uint256 public value2;
    uint8 public count;
    uint256 public value3;
    bool public flag2;

    // 使用 6 个存储槽
    // 槽位 0: value1 (32 bytes)
    // 槽位 1: flag1 (1 byte) + 浪费 31 bytes
    // 槽位 2: value2 (32 bytes)
    // 槽位 3: count (1 byte) + 浪费 31 bytes
    // 槽位 4: value3 (32 bytes)
    // 槽位 5: flag2 (1 byte) + 浪费 31 bytes
}