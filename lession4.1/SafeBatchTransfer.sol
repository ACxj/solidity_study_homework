// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeBatchTransfer {
    // 最大批量转账数量限制，防止 gas 溢出
    uint256 private constant MAX_BATCH_SIZE = 100;

    // 用户余额映射
    mapping(address => uint256) public balances;

    // 错误定义
    error ArrayLengthMismatch();      // 数组长度不匹配
    error BatchSizeExceeded();        // 批量大小超限
    error InsufficientBalance();      // 余额不足
    error ZeroAddress();             // 地址为零地址
    error TransferFailed();           // 转账失败

    // 事件
    // 批量转账完成时触发
    event BatchTransfer(address indexed from, address[] recipients, uint256[] amounts);

    /**
     * @notice 批量转账函数
     * @param recipients 收款地址数组
     * @param amounts 收款金额数组（与 recipients 一一对应）
     * @return 是否转账成功
     */
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external returns (bool) {
        // ========== 第一步：数组基础验证 ==========
        // 检查两个数组长度是否一致
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();
        // 检查数组是否为空
        if (recipients.length == 0) revert ArrayLengthMismatch();
        // 检查批量大小是否超过上限
        if (recipients.length > MAX_BATCH_SIZE) revert BatchSizeExceeded();

        // ========== 第二步：遍历验证地址并计算总额 ==========
        uint256 totalAmount;  // 初始化总金额
        uint256 len = recipients.length;  // 缓存数组长度，避免重复访问

        for (uint256 i = 0; i < len; ++i) {
            // 检查每个收款地址是否为有效地址（非零地址）
            if (recipients[i] == address(0)) revert ZeroAddress();
            // 累加总金额
            totalAmount += amounts[i];
        }

        // ========== 第三步：预先检查发送者余额 ==========
        // 在执行转账前先检查余额是否充足
        if (balances[msg.sender] < totalAmount) revert InsufficientBalance();

        // ========== 第四步：原子性执行转账 ==========
        // 先从发送者扣款（如果这里失败，整个交易 revert）
        balances[msg.sender] -= totalAmount;

        // 再依次给每个收款地址转账
        for (uint256 i = 0; i < len; ++i) {
            balances[recipients[i]] += amounts[i];
        }

        // ========== 第五步：记录事件并返回 ==========
        emit BatchTransfer(msg.sender, recipients, amounts);
        return true;
    }

    /**
     * @notice 存款函数，用户向合约充值
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /**
     * @notice 查询用户余额
     * @return 用户当前的余额
     */
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @notice 查询最大批量转账数量限制
     * @return 最大批量大小
     */
    function getMaxBatchSize() external pure returns (uint256) {
        return MAX_BATCH_SIZE;
    }
}