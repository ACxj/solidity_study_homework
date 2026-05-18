// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentContract {
    uint256 private constant MIN_DEPOSIT = 0.01 ether;

    mapping(address => uint256) private balances;
    address public owner;
    bool public paused;

    error NotOwner();
    error ContractPaused();
    error InsufficientBalance();
    error BelowMinimumDeposit();
    error WithdrawFailed();

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Paused();
    event Unpaused();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    function deposit() external payable whenNotPaused {
        if (msg.value < MIN_DEPOSIT) revert BelowMinimumDeposit();

        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert WithdrawFailed();

        emit Withdrawn(msg.sender, amount);
    }

    function pause() external onlyOwner {
        if (paused) return;
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        if (!paused) return;
        paused = false;
        emit Unpaused();
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getMinDeposit() external pure returns (uint256) {
        return MIN_DEPOSIT;
    }
}