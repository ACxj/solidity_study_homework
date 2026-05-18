// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 暂停功能合约
contract Pausable {
    bool public paused;

    event Paused(address account);
    event Unpaused(address account);

    error ContractPaused();

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    constructor() {
        paused = false;
    }

    // 暂停合约（内部函数）
    function pause() internal {
        if (!paused) {
            paused = true;
            emit Paused(msg.sender);
        }
    }

    // 恢复合约（内部函数）
    function unpause() internal {
        if (paused) {
            paused = false;
            emit Unpaused(msg.sender);
        }
    }
}