// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FunctionOptimizationOriginal {
    mapping(address => uint256) public balances;

    // 原始版本
    function transfer(address to, uint256 amount) public {
        require(expensiveCheck(), "Expensive check failed");
        require(amount > 0, "Amount must be greater than 0");
        require(to != address(0), "Invalid recipient");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function expensiveCheck() internal pure returns (bool) {
        return true;
    }
}

// 优化版本
contract FunctionOptimizationOptimized {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) external {
        // 1. 便宜的检查在前（短路求值）
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");

        // 2. expensiveCheck 放在后面（可能 revert，节省 gas）
        require(expensiveCheck(), "Expensive check failed");

        // 3. 使用局部变量减少存储访问
        mapping(address => uint256) storage balancesMap = balances;

        uint256 senderBalance = balancesMap[msg.sender];
        require(senderBalance >= amount, "Insufficient balance");

        // 4. CEI 模式：先更新状态
        balancesMap[msg.sender] = senderBalance - amount;
        balancesMap[to] += amount;
    }

    function expensiveCheck() internal pure returns (bool) {
        return true;
    }
}
