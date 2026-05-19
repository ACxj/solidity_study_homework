// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 计数器库
library CounterLib {
    struct Counter {
        uint256 value;
    }

    function increment(Counter storage c) internal {
        c.value++;
    }

    function decrement(Counter storage c) internal {
        require(c.value > 0, "Counter underflow");
        c.value--;
    }

    function add(Counter storage c, uint256 amount) internal {
        c.value += amount;
    }

    function subtract(Counter storage c, uint256 amount) internal {
        require(c.value >= amount, "Counter underflow");
        c.value -= amount;
    }

    function reset(Counter storage c) internal {
        c.value = 0;
    }

    function get(Counter storage c) internal view returns (uint256) {
        return c.value;
    }

    function incrementBy(Counter storage c, uint256 n) internal {
        c.value += n;
    }

    function doubleValue(Counter storage c) internal {
        c.value *= 2;
    }

    function isZero(Counter storage c) internal view returns (bool) {
        return c.value == 0;
    }
}