// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Animal.sol";

// 猫合约
contract Cat is Animal {
    constructor(string memory _name) Animal(_name) {}

    function makeSound() external pure override returns (string memory) {
        return "Meow! Meow!";
    }

    function eat() external pure override returns (string memory) {
        return "Cat is eating fish...";
    }
}