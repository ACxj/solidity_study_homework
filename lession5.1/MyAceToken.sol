// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyAceToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool public paused;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Paused(address account);
    event Unpaused(address account);

    error InsufficientBalance();
    error InsufficientAllowance();
    error ZeroAmount();
    error ZeroAddress();
    error ArrayLengthMismatch();
    error BatchSizeExceeded();
    error ContractPaused();
    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    constructor(uint256 _initialSupply) {
        if (_initialSupply == 0) revert ZeroAmount();

        owner = msg.sender;
        name = "Ace Token";
        symbol = "ACE";
        decimals = 18;
        totalSupply = _initialSupply * 10 ** decimals;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function pause() external onlyOwner {
        if (!paused) {
            paused = true;
            emit Paused(msg.sender);
        }
    }

    function unpause() external onlyOwner {
        if (paused) {
            paused = false;
            emit Unpaused(msg.sender);
        }
    }

    // 转账
    function transfer(address to, uint256 amount) external whenNotPaused returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // 授权
    function approve(address spender, uint256 amount) external whenNotPaused returns (bool) {
        if (spender == address(0)) revert ZeroAddress();

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 授权转账
    function transferFrom(address from, address to, uint256 amount) external whenNotPaused returns (bool) {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (balanceOf[from] < amount) revert InsufficientBalance();
        if (allowance[from][msg.sender] < amount) revert InsufficientAllowance();

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    // 铸造代币
    function mint(address to, uint256 amount) external whenNotPaused returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    // 销毁代币
    function burn(uint256 amount) external whenNotPaused returns (bool) {
        if (amount == 0) revert ZeroAmount();
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    // 批量转账
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) external whenNotPaused returns (bool) {
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();
        if (recipients.length == 0) revert ZeroAmount();
        if (recipients.length > 50) revert BatchSizeExceeded();

        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert ZeroAddress();
            totalAmount += amounts[i];
        }

        if (balanceOf[msg.sender] < totalAmount) revert InsufficientBalance();

        for (uint256 i = 0; i < recipients.length; i++) {
            balanceOf[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }

        balanceOf[msg.sender] -= totalAmount;
        return true;
    }
}