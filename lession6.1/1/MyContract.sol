// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";

// 组合 Ownable 和 Pausable 的示例合约
contract MyContract is Ownable, Pausable {
    uint256 public value;
    mapping(address => uint256) public balances;

    event ValueSet(uint256 oldValue, uint256 newValue);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    error InsufficientBalance();
    error ZeroAmount();

    constructor() {
        value = 0;
    }

    // 设置值（仅所有者，合约未暂停时可用）
    function setValue(uint256 newValue) external onlyOwner whenNotPaused {
        uint256 oldValue = value;
        value = newValue;
        emit ValueSet(oldValue, newValue);
    }

    // 存款
    function deposit() external payable whenNotPaused {
        if (msg.value == 0) revert ZeroAmount();
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // 取款
    function withdraw(uint256 amount) external whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    // 暂停合约（仅所有者）
    function pauseContract() external onlyOwner {
        pause();
    }

    // 恢复合约（仅所有者）
    function unpauseContract() external onlyOwner {
        unpause();
    }
}