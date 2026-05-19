// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin 库演示合约

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OpenZeppelinDemo {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // ========== Strings 库演示 ==========

    function demoStrings() public pure returns (string memory) {
        string memory a = "Hello";
        string memory b = " World";

        // 字符串拼接
        string memory combined = string.concat(a, b);
        return combined;
    }

    function demoUintToString() public pure returns (string memory) {
        uint256 num = 12345;
        return Strings.toString(num);
    }

    function demoAddressToString() public view returns (string memory) {
        return Strings.toHexString(msg.sender);
    }

    // ========== Address 库演示 ==========

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function demoIsContract() public view returns (bool) {
        return isContract(address(this));
    }

    function demoSendValue(address payable recipient) public payable {
        require(msg.value > 0, "No ETH sent");
        Address.sendValue(recipient, msg.value);
    }

    function demoFunctionCall(address target, bytes memory data) public returns (bytes memory) {
        // 安全调用合约函数
        return Address.functionCall(target, data);
    }

    // ========== EnumerableSet 演示 ==========

    EnumerableSet.AddressSet private whitelist;
    EnumerableSet.UintSet private numbers;

    function demoAddToWhitelist(address addr) external returns (bool) {
        return whitelist.add(addr);
    }

    function demoRemoveFromWhitelist(address addr) external returns (bool) {
        return whitelist.remove(addr);
    }

    function demoCheckWhitelist(address addr) external view returns (bool) {
        return whitelist.contains(addr);
    }

    function demoGetWhitelistLength() external view returns (uint256) {
        return whitelist.length();
    }

    function demoGetWhitelistAddress(uint256 index) external view returns (address) {
        return whitelist.at(index);
    }

    function demoGetAllWhitelist() external view returns (address[] memory) {
        return whitelist.values();
    }

    // UintSet 演示
    function demoAddNumber(uint256 num) external returns (bool) {
        return numbers.add(num);
    }

    function demoRemoveNumber(uint256 num) external returns (bool) {
        return numbers.remove(num);
    }

    function demoContainsNumber(uint256 num) external view returns (bool) {
        return numbers.contains(num);
    }

    function demoGetNumbersLength() external view returns (uint256) {
        return numbers.length();
    }

    function demoGetNumberAt(uint256 index) external view returns (uint256) {
        return numbers.at(index);
    }

    // ========== ERC20 + Address 组合演示 ==========

    function demoTransferToContract(address token, address recipient, uint256 amount) external {
        require(isContract(recipient), "Not a contract");
        IERC20(token).transfer(recipient, amount);
    }

    function demoSafeTransferFrom(address token, address from, address to, uint256 amount) external {
        SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
    }
}