// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// 简单的代币合约
contract SimpleToken is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// 代币工厂
contract TokenFactory {
    // 代币信息结构
    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address creator;
        uint256 createdAt;
    }

    // 所有创建的代币列表
    TokenInfo[] public allTokens;

    // 记录每个用户创建的代币地址
    mapping(address => address[]) public tokensByCreator;

    // 事件
    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol
    );

    // 创建单个代币
    function createToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply
    ) external returns (address) {
        SimpleToken token = new SimpleToken(
            name,
            symbol,
            decimals,
            initialSupply
        );

        // 记录代币信息
        allTokens.push(TokenInfo({
            tokenAddress: address(token),
            name: name,
            symbol: symbol,
            decimals: decimals,
            totalSupply: initialSupply,
            creator: msg.sender,
            createdAt: block.timestamp
        }));

        // 记录用户的代币
        tokensByCreator[msg.sender].push(address(token));

        emit TokenCreated(address(token), msg.sender, name, symbol);

        return address(token);
    }

    // 批量创建代币
    function createTokens(
        string[] memory names,
        string[] memory symbols,
        uint8[] memory decimals,
        uint256[] memory supplies
    ) external returns (address[] memory) {
        if (names.length != symbols.length ||
            names.length != decimals.length ||
            names.length != supplies.length) {
            revert("Array length mismatch");
        }

        address[] memory created = new address[](names.length);

        for (uint256 i = 0; i < names.length; i++) {
            SimpleToken token = new SimpleToken(
                names[i],
                symbols[i],
                decimals[i],
                supplies[i]
            );

            created[i] = address(token);

            allTokens.push(TokenInfo({
                tokenAddress: address(token),
                name: names[i],
                symbol: symbols[i],
                decimals: decimals[i],
                totalSupply: supplies[i],
                creator: msg.sender,
                createdAt: block.timestamp
            }));

            tokensByCreator[msg.sender].push(address(token));

            emit TokenCreated(address(token), msg.sender, names[i], symbols[i]);
        }

        return created;
    }

    // 获取所有代币数量
    function getTotalTokens() external view returns (uint256) {
        return allTokens.length;
    }

    // 获取用户创建的代币数量
    function getCreatorTokenCount(address creator) external view returns (uint256) {
        return tokensByCreator[creator].length;
    }

    // 获取用户创建的所有代币
    function getTokensByCreator(address creator) external view returns (address[] memory) {
        return tokensByCreator[creator];
    }

    // 获取所有代币信息
    function getAllTokens() external view returns (TokenInfo[] memory) {
        return allTokens;
    }

    // 获取指定范围的代币
    function getTokensByRange(uint256 start, uint256 end) external view returns (TokenInfo[] memory) {
        if (start >= end || end > allTokens.length) {
            revert("Invalid range");
        }

        TokenInfo[] memory result = new TokenInfo[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = allTokens[i];
        }
        return result;
    }
}

// 优化版本 - 使用 EnumerableSet 减少 Gas
contract TokenFactoryOptimized {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address creator;
        uint256 createdAt;
    }

    // 使用 EnumerableSet 存储所有代币
    EnumerableSet.AddressSet private allTokensSet;

    // 代币信息映射
    mapping(address => TokenInfo) public tokenInfoMap;

    // 每个创建者的代币集合
    mapping(address => EnumerableSet.AddressSet) private tokensByCreator;

    event TokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol
    );

    function createToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply
    ) external returns (address) {
        SimpleToken token = new SimpleToken(
            name,
            symbol,
            decimals,
            initialSupply
        );

        address tokenAddr = address(token);

        tokenInfoMap[tokenAddr] = TokenInfo({
            tokenAddress: tokenAddr,
            name: name,
            symbol: symbol,
            decimals: decimals,
            totalSupply: initialSupply,
            creator: msg.sender,
            createdAt: block.timestamp
        });

        allTokensSet.add(tokenAddr);
        tokensByCreator[msg.sender].add(tokenAddr);

        emit TokenCreated(tokenAddr, msg.sender, name, symbol);

        return tokenAddr;
    }

    function getTotalTokens() external view returns (uint256) {
        return allTokensSet.length();
    }

    function getCreatorTokenCount(address creator) external view returns (uint256) {
        return tokensByCreator[creator].length();
    }

    function getTokenByIndex(uint256 index) external view returns (TokenInfo memory) {
        address tokenAddr = allTokensSet.at(index);
        return tokenInfoMap[tokenAddr];
    }

    function getTokensByCreator(address creator) external view returns (address[] memory) {
        uint256 count = tokensByCreator[creator].length();
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tokensByCreator[creator].at(i);
        }
        return result;
    }

    function getTokensByCreatorPaginated(address creator, uint256 offset, uint256 limit)
        external view returns (address[] memory)
    {
        uint256 count = tokensByCreator[creator].length();
        if (offset >= count) return new address[](0);

        uint256 size = offset + limit > count ? count - offset : limit;
        address[] memory result = new address[](size);

        for (uint256 i = 0; i < size; i++) {
            result[i] = tokensByCreator[creator].at(offset + i);
        }

        return result;
    }
}
