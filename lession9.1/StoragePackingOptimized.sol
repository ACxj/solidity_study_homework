// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 优化版本 - 存储打包
contract StoragePackingOptimized {
    uint256 public value1;
    uint256 public value2;
    uint256 public value3;
    bool public flag1;
    bool public flag2;
    uint8 public count;

    // 使用 4 个存储槽
    // 槽位 0: value1 (32 bytes)
    // 槽位 1: value2 (32 bytes)
    // 槽位 2: value3 (32 bytes)
    // 槽位 3: flag1 + flag2 + count (1+1+1 = 3 bytes) 打包在一起
}