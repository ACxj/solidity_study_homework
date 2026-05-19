// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReentrancyGuardVault {
    mapping(address => uint256) public balances;

    bool private reentrancyLock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ReentrancyAttackAttempted();

    modifier noReentrancy() {
        if (reentrancyLock) {
            emit ReentrancyAttackAttempted();
            revert("Reentrancy detected");
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external noReentrancy {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
