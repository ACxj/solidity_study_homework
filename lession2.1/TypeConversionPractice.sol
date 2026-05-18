// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TypeConversionPractice {

    error ExceedsUint8Max();

    event ConvertedToUint8(uint256 input, uint8 output);
    event StringCompareResult(string a, string b, bool result);
    event ZeroAddressCheck(address addr, bool isZero);

    function safeConvertToUint8(uint256 value) public pure returns (uint8) {
        if (value > 255) revert ExceedsUint8Max();
        return uint8(value);
    }

    function testSafeConvertSuccess() external {
        uint256 validValue = 100;
        uint8 result = safeConvertToUint8(validValue);
        emit ConvertedToUint8(validValue, result);
    }

    function testSafeConvertFailure() external pure {
        uint256 invalidValue = 256;
        safeConvertToUint8(invalidValue);
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function testCompareStrings() external {
        bool result1 = compareStrings("hello", "hello");
        emit StringCompareResult("hello", "hello", result1);

        bool result2 = compareStrings("hello", "world");
        emit StringCompareResult("hello", "world", result2);
    }

    function isZeroAddress(address addr) public pure returns (bool) {
        return addr == address(0);
    }

    function testIsZeroAddress() external {
        address zeroAddr = address(0);
        bool result1 = isZeroAddress(zeroAddr);
        emit ZeroAddressCheck(zeroAddr, result1);

        address nonZeroAddr = address(0x1234567890123456789012345678901234567890);
        bool result2 = isZeroAddress(nonZeroAddr);
        emit ZeroAddressCheck(nonZeroAddr, result2);
    }
}