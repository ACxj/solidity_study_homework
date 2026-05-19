// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSwap {
    event SwapRequested(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event SwapCompleted(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event SwapFailed(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        string reason
    );

    error ZeroAmount();
    error SameToken();
    error InsufficientBalance(uint256 available, uint256 requested);
    error TransferFailed(string operation);

    function swap(
        address tokenA,
        address tokenB,
        uint256 amount
    ) external returns (bool) {
        if (amount == 0) revert ZeroAmount();
        if (tokenA == tokenB) revert SameToken();

        IERC20(tokenA).transferFrom(msg.sender, address(this), amount);

        bool success = IERC20(tokenB).transfer(msg.sender, amount);
        if (!success) {
            IERC20(tokenA).transfer(msg.sender, amount);
            emit SwapFailed(msg.sender, tokenA, tokenB, amount, 0, "TokenB transfer failed");
            revert TransferFailed("TokenB transfer failed");
        }

        emit SwapCompleted(msg.sender, tokenA, tokenB, amount, amount);
        return true;
    }

    function getSwapQuote(
        address tokenA,
        address tokenB,
        uint256 amount
    ) external pure returns (uint256) {
        if (tokenA == tokenB) return amount;
        return amount;
    }
}