// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SecureBank {
    mapping(address => uint256) private balances;
    mapping(address => bool) private reentrancyLock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    error ZeroAmount();
    error ReentrancyBlocked();
    error InsufficientBalance(uint256 balance, uint256 amount);
    error TransferFailed();

    modifier noReentrancy() {
        if (reentrancyLock[msg.sender]) revert ReentrancyBlocked();
        reentrancyLock[msg.sender] = true;
        _;
        reentrancyLock[msg.sender] = false;
    }

    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external noReentrancy {
        if (amount == 0) revert ZeroAmount();

        uint256 balance = balances[msg.sender];
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }

        // CEI 模式：先更新状态
        balances[msg.sender] = balance - amount;

        // 后外部调用
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdraw(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
