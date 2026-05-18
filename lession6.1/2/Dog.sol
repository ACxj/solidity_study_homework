// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Animal.sol";

// 狗合约
contract Dog is Animal {
    constructor(string memory _name) Animal(_name) {}

    function makeSound() external pure override returns (string memory) {
        return "Woof! Woof!";
    }

    function eat() external pure override returns (string memory) {
        return "Dog is eating kibble...";
    }
}