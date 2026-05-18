// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagementSystem {
    uint256 private constant MAX_USERS = 1000;

    struct User {
        address walletAddress;
        string name;
        string email;
        uint256 balance;
        bool isRegistered;
        uint256 registeredAt;
    }

    mapping(address => User) private users;
    address[] private userAddresses;

    error UserAlreadyRegistered();
    error UserNotFound();
    error MaxUsersReached();
    error InvalidInput();
    error ZeroAddress();

    event UserRegistered(address indexed user, string name, string email);
    event UserUpdated(address indexed user, string name, string email);
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);

    modifier onlyRegistered() {
        if (!users[msg.sender].isRegistered) revert UserNotFound();
        _;
    }

    function register(string memory name, string memory email) external {
        if (bytes(name).length == 0 || bytes(email).length == 0) revert InvalidInput();
        if (users[msg.sender].isRegistered) revert UserAlreadyRegistered();
        if (userAddresses.length >= MAX_USERS) revert MaxUsersReached();

        users[msg.sender] = User({
            walletAddress: msg.sender,
            name: name,
            email: email,
            balance: 0,
            isRegistered: true,
            registeredAt: block.timestamp
        });

        userAddresses.push(msg.sender);
        emit UserRegistered(msg.sender, name, email);
    }

    function updateProfile(string memory name, string memory email) external onlyRegistered {
        if (bytes(name).length == 0 || bytes(email).length == 0) revert InvalidInput();

        User storage user = users[msg.sender];
        user.name = name;
        user.email = email;

        emit UserUpdated(msg.sender, name, email);
    }

    function deposit() external payable onlyRegistered {
        if (msg.value == 0) revert InvalidInput();

        User storage user = users[msg.sender];
        user.balance += msg.value;

        emit Deposit(msg.sender, msg.value, user.balance);
    }

    function getUser(address userAddress) external view returns (User memory) {
        if (!users[userAddress].isRegistered) revert UserNotFound();
        return users[userAddress];
    }

    function getMyProfile() external view onlyRegistered returns (User memory) {
        return users[msg.sender];
    }

    function getAllUsers() external view returns (address[] memory) {
        return userAddresses;
    }

    function getUsersByRange(uint256 start, uint256 length) external view returns (address[] memory result) {
        uint256 total = userAddresses.length;
        if (start >= total) revert InvalidInput();

        uint256 end = start + length;
        if (end > total) {
            end = total;
        }

        uint256 resultLength = end - start;
        result = new address[](resultLength);

        for (uint256 i = 0; i < resultLength; ++i) {
            result[i] = userAddresses[start + i];
        }
    }

    function getUserCount() external view returns (uint256 count, uint256 max) {
        return (userAddresses.length, MAX_USERS);
    }
}