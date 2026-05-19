// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BatchTransferExercise {
    uint256 private constant MAX_BATCH_SIZE = 100;
    uint256 private constant TRANSFER_GAS = 2300;

    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event BatchTransfer(address indexed from, uint256 totalAmount, uint256 count);

    error ExceedBatchLimit();
    error ArrayLengthMismatch();
    error InsufficientBalance();
    error TransferFailed();

    // 批量转账
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        // 1. 检查批量大小
        if (recipients.length > MAX_BATCH_SIZE) revert ExceedBatchLimit();

        // 2. 检查数组长度一致性
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();

        // 3. 计算总额（使用局部变量减少存储访问）
        uint256 totalAmount = 0;
        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; ) {
            totalAmount += amounts[i];
            unchecked { ++i; }
        }

        // 4. 检查余额
        uint256 senderBalance = balances[msg.sender];
        if (senderBalance < totalAmount) revert InsufficientBalance();

        // 5. 先扣除总额（CEI 模式）
        balances[msg.sender] = senderBalance - totalAmount;

        // 6. 执行批量转账
        for (uint256 i = 0; i < length; ) {
            address to = recipients[i];
            uint256 amount = amounts[i];

            // 检查目标地址有效性
            if (to != address(0) && amount > 0) {
                balances[to] += amount;
                emit Transfer(msg.sender, to, amount);
            }

            unchecked { ++i; }
        }

        emit BatchTransfer(msg.sender, totalAmount, length);
    }

    // 存款
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 获取余额
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }
}
