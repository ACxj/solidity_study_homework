// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 动物抽象合约
abstract contract Animal {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    // 抽象函数：发出声音
    function makeSound() external pure virtual returns (string memory);

    // 共同功能：吃
    function eat() external pure virtual returns (string memory) {
        return "eating...";
    }
}