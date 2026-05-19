// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CounterLib.sol";

contract CounterContract {
    using CounterLib for CounterLib.Counter;

    CounterLib.Counter public count;

    function increment() external {
        count.increment();
    }

    function decrement() external {
        count.decrement();
    }

    function add(uint256 amount) external {
        count.add(amount);
    }

    function subtract(uint256 amount) external {
        count.subtract(amount);
    }

    function reset() external {
        count.reset();
    }

    function get() external view returns (uint256) {
        return count.get();
    }

    function incrementBy(uint256 n) external {
        count.incrementBy(n);
    }

    function doubleValue() external {
        count.doubleValue();
    }

    function isZero() external view returns (bool) {
        return count.isZero();
    }
}