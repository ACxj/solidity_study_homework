// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageLayout {
    address public implementation;
    address public admin;
    uint256 public version;

    mapping(bytes32 => uint256) public uintStorage;
    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => bytes) public bytesStorage;
}
