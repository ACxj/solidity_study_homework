// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageBoard {
    uint256 private constant MAX_MESSAGE_LENGTH = 280;

    event MessagePosted(
        address indexed user,
        string content,
        uint256 timestamp
    );

    error EmptyMessage();
    error MessageTooLong();

    function postMessage(string calldata message) external {
        if (bytes(message).length == 0) revert EmptyMessage();
        if (bytes(message).length > MAX_MESSAGE_LENGTH) revert MessageTooLong();

        emit MessagePosted(msg.sender, message, block.timestamp);
    }
}