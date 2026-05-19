// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableContract {
    address public owner;
    address public newOwner;
    uint256 public minimumContribution = 0.1 ether;
    uint256 public deadline;
    uint256 public goal;
    uint256 public raisedAmount;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public whitelist;
    address[] public contributorList;

    event ContributionReceived(address contributor, uint256 amount);
    event RefundClaimed(address contributor, uint256 amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(uint256 _goal, uint256 _duration) {
        goal = _goal;
        deadline = block.timestamp + _duration;
        owner = msg.sender;
    }

    function contribute() external payable {
        require(msg.value >= minimumContribution);
        require(block.timestamp < deadline);
        require(whitelist[msg.sender]);

        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;
        contributorList.push(msg.sender);

        emit ContributionReceived(msg.sender, msg.value);
    }

    function addToWhitelist(address[] memory addresses) external {
        require(msg.sender == owner);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function claimRefund() external {
        require(block.timestamp >= deadline);
        require(raisedAmount < goal);

        uint256 amount = contributions[msg.sender];
        require(amount > 0);

        contributions[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit RefundClaimed(msg.sender, amount);
    }

    function withdraw() external {
        require(msg.sender == owner);
        require(raisedAmount >= goal);
        require(block.timestamp >= deadline);

        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function changeOwner(address newOwnerAddr) external {
        require(msg.sender == owner);
        newOwner = newOwnerAddr;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        owner = newOwner;
        newOwner = address(0);
        emit OwnerChanged(owner, newOwner);
    }

    receive() external payable {
        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }
}
