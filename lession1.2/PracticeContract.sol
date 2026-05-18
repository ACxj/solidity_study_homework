// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PracticeContract {
    uint256[] public numbers;
    address public admin;
    uint256 public constant MULTIPLIER = 2;

    constructor() {
        admin = msg.sender;
    }
    
    function batchProcess(
        uint256[] calldata inputs
    ) external {
        require(msg.sender == admin);

        uint256 len = inputs.length;
        for (uint256 i = 0; i < len; ++i) {
            numbers.push(inputs[i] * MULTIPLIER);
        }
    }
    
    function getSum() external view returns (uint256) {
        require(msg.sender == admin);

        uint256 sum;
        uint256 len = numbers.length;
        for (uint256 i = 0; i < len; ++i) {
            sum += numbers[i];
        }
        return sum;
    }
}