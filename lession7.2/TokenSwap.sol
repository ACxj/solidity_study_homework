// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSwap {
    struct SwapRequest {
        address user;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        bool completed;
    }

    mapping(bytes32 => SwapRequest) public swapRequests;

    event SwapRequested(bytes32 indexed swapId, address indexed user, uint256 amountA, uint256 amountB);
    event SwapCompleted(bytes32 indexed swapId);
    event SwapFailed(bytes32 indexed swapId, string reason);

    error InvalidAmount();
    error SameToken();
    error SwapAlreadyCompleted();
    error TransferFailed();

    function requestSwap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external returns (bytes32) {
        if (amountA == 0 || amountB == 0) revert InvalidAmount();
        if (tokenA == tokenB) revert SameToken();

        bytes32 swapId = keccak256(abi.encodePacked(msg.sender, tokenA, tokenB, amountA, block.timestamp));

        swapRequests[swapId] = SwapRequest({
            user: msg.sender,
            tokenA: tokenA,
            tokenB: tokenB,
            amountA: amountA,
            amountB: amountB,
            completed: false
        });

        emit SwapRequested(swapId, msg.sender, amountA, amountB);
        return swapId;
    }

    function executeSwap(bytes32 swapId) external {
        SwapRequest storage request = swapRequests[swapId];
        if (request.completed) revert SwapAlreadyCompleted();

        IERC20 tokenA = IERC20(request.tokenA);
        IERC20 tokenB = IERC20(request.tokenB);

        // 尝试从用户转出 tokenA
        try tokenA.transferFrom(request.user, address(this), request.amountA) returns (bool success) {
            if (!success) {
                emit SwapFailed(swapId, "TokenA transfer failed");
                revert TransferFailed();
            }
        } catch Error(string memory reason) {
            emit SwapFailed(swapId, reason);
            revert(reason);
        } catch Panic(uint256 errorCode) {
            emit SwapFailed(swapId, "Panic occurred");
            revert();
        } catch (bytes memory lowLevelData) {
            emit SwapFailed(swapId, "Low level error");
            revert();
        }

        // 尝试给用户转出 tokenB
        try tokenB.transfer(request.user, request.amountB) returns (bool success) {
            if (!success) {
                tokenA.transfer(request.user, request.amountA);
                emit SwapFailed(swapId, "TokenB transfer failed - rolled back TokenA");
                revert TransferFailed();
            }
        } catch Error(string memory reason) {
            tokenA.transfer(request.user, request.amountA);
            emit SwapFailed(swapId, string.concat("TokenB transfer failed: ", reason));
            revert(reason);
        } catch Panic(uint256 errorCode) {
            tokenA.transfer(request.user, request.amountA);
            emit SwapFailed(swapId, "Panic in TokenB transfer");
            revert();
        } catch (bytes memory lowLevelData) {
            tokenA.transfer(request.user, request.amountA);
            emit SwapFailed(swapId, "Low level error in TokenB transfer");
            revert();
        }

        request.completed = true;
        emit SwapCompleted(swapId);
    }

    function getSwapRequest(bytes32 swapId) external view returns (SwapRequest memory) {
        return swapRequests[swapId];
    }
}