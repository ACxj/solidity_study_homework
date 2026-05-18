// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UnoptimizedCode {
    uint[] public data;

    function processOptimized(uint[] calldata values) public {
        uint256 len = values.length;
        uint256 threshold = 10;
        uint256 count;
        for (uint256 i = 0; i < len; ++i) {
            if (values[i] > threshold) {
                ++count;
            }
        }
        uint256 startIndex = data.length;
        data.length = startIndex + count;
        count = 0;
        for (uint256 i = 0; i < len; ++i) {
            if (values[i] > threshold) {
                data[startIndex + count] = values[i];
                ++count;
            }
        }
    }

    function process(uint[] calldata values) public {
        uint256 len = values.length;
        uint256 threshold = 10;
        for (uint256 i = 0; i < len; ++i) {
            if (values[i] > threshold) {
                data.push(values[i]);
            }
        }
    }
}