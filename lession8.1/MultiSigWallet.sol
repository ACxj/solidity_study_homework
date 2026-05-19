// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    uint256 public constant MAX_OWNER_COUNT = 10;
    uint256 public constant GAS_LIMIT = 5000;

    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;

    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 gasLimit;
    }

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event TransactionFailed(uint256 indexed txIndex, bytes reason);

    error NotOwner();
    error AlreadyOwner();
    error InvalidOwnerCount();
    error NotConfirmed();
    error AlreadyConfirmed();
    error AlreadyExecuted();
    error ExecutionFailed();
    error InvalidValue();
    error ReentrancyBlocked();

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier notExecuted(uint256 txIndex) {
        if (transactions[txIndex].executed) revert AlreadyExecuted();
        _;
    }

    bool private reentrancyLock;

    modifier noReentrancy() {
        if (reentrancyLock) revert ReentrancyBlocked();
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(address[] memory _owners, uint256 _required) {
        if (_owners.length == 0 || _owners.length > MAX_OWNER_COUNT) {
            revert InvalidOwnerCount();
        }
        if (_required == 0 || _required > _owners.length) {
            revert InvalidOwnerCount();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            if (isOwner[_owners[i]]) revert AlreadyOwner();
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        required = _required;
    }

    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (uint256) {
        if (value > address(this).balance) revert InvalidValue();

        uint256 txIndex = transactionCount++;
        transactions[txIndex] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            gasLimit: GAS_LIMIT
        });

        emit SubmitTransaction(msg.sender, txIndex, to, value);
        confirmTransaction(txIndex);
        return txIndex;
    }

    function confirmTransaction(uint256 txIndex)
        public
        onlyOwner
        notExecuted(txIndex)
    {
        if (confirmations[txIndex][msg.sender]) revert AlreadyConfirmed();

        confirmations[txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, txIndex);

        if (getConfirmationCount(txIndex) >= required) {
            executeTransaction(txIndex);
        }
    }

    function revokeConfirmation(uint256 txIndex)
        public
        onlyOwner
        notExecuted(txIndex)
    {
        if (!confirmations[txIndex][msg.sender]) revert NotConfirmed();

        confirmations[txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, txIndex);
    }

    function executeTransaction(uint256 txIndex)
        public
        onlyOwner
        notExecuted(txIndex)
        noReentrancy
    {
        if (getConfirmationCount(txIndex) < required) revert NotConfirmed();

        Transaction storage txn = transactions[txIndex];
        txn.executed = true;

        (bool success, bytes memory reason) = txn.to.call{value: txn.value, gas: txn.gasLimit}(txn.data);

        if (!success) {
            txn.executed = false;
            emit TransactionFailed(txIndex, reason);
            revert ExecutionFailed();
        }

        emit ExecuteTransaction(msg.sender, txIndex);
    }

    function getConfirmationCount(uint256 txIndex) public view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[txIndex][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function getConfirmations(uint256 txIndex) public view returns (address[] memory) {
        address[] memory confirmationsList = new address[](getConfirmationCount(txIndex));
        uint256 count;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[txIndex][owners[i]]) {
                confirmationsList[count++] = owners[i];
            }
        }
        return confirmationsList;
    }

    function getTransactionIds(bool executed) public view returns (uint256[] memory) {
        uint256 count;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (transactions[i].executed == executed) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (transactions[i].executed == executed) {
                result[index++] = i;
            }
        }
        return result;
    }

    receive() external payable {}
}