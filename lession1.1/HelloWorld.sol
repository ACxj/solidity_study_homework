// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    string public message;
    address public owner;

    constructor() {
        message = "Hello, Solidity!";
        owner = msg.sender;
    }

    function updateMessage(string memory newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
}