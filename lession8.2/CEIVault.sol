// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CEIVault {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        // CEI 模式：Checks-Effects-Interactions

        // 1. Checks（检查）
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 2. Effects（状态更新）
        balances[msg.sender] -= amount;

        // 3. Interactions（外部调用）
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
