// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 confirmations;
    }

    address[] public signers;
    uint256 public requiredConfirmations;
    mapping(address => bool) public isSigner;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    error NotSigner();
    error NotEnoughSigners();
    error TxNotFound();
    error AlreadyExecuted();
    error AlreadyConfirmed();
    error NotConfirmed();
    error InsufficientConfirmations();
    error ExecutionFailed();
    error ZeroAddress();

    event SubmitTransaction(uint256 indexed txIndex, address indexed to, uint256 value);
    event ConfirmTransaction(uint256 indexed txIndex, address indexed signer);
    event RevokeConfirmation(uint256 indexed txIndex, address indexed signer);
    event ExecuteTransaction(uint256 indexed txIndex, address indexed to, uint256 value);

    modifier onlySigner() {
        if (!isSigner[msg.sender]) revert NotSigner();
        _;
    }

    function deposit() external payable {
    }

    constructor(address[] memory _signers, uint256 _requiredConfirmations) {
        if (_signers.length < 2) revert NotEnoughSigners();
        if (_requiredConfirmations > _signers.length) revert NotEnoughSigners();
        if (_requiredConfirmations == 0) revert NotEnoughSigners();

        for (uint256 i = 0; i < _signers.length; ++i) {
            if (_signers[i] == address(0)) revert ZeroAddress();
            if (isSigner[_signers[i]]) revert NotEnoughSigners();
            isSigner[_signers[i]] = true;
        }

        signers = _signers;
        requiredConfirmations = _requiredConfirmations;
    }

    function submitTransaction(address to, uint256 value) external onlySigner returns (uint256) {
        if (to == address(0)) revert ZeroAddress();

        uint256 txIndex = transactions.length;
        transactions.push(Transaction({
            to: to,
            value: value,
            executed: false,
            confirmations: 0
        }));

        emit SubmitTransaction(txIndex, to, value);
        return txIndex;
    }

    function confirmTransaction(uint256 txIndex) external onlySigner {
        if (txIndex >= transactions.length) revert TxNotFound();
        if (transactions[txIndex].executed) revert AlreadyExecuted();
        if (confirmations[txIndex][msg.sender]) revert AlreadyConfirmed();

        confirmations[txIndex][msg.sender] = true;
        ++transactions[txIndex].confirmations;

        emit ConfirmTransaction(txIndex, msg.sender);
    }

    function revokeConfirmation(uint256 txIndex) external onlySigner {
        if (txIndex >= transactions.length) revert TxNotFound();
        if (transactions[txIndex].executed) revert AlreadyExecuted();
        if (!confirmations[txIndex][msg.sender]) revert NotConfirmed();

        confirmations[txIndex][msg.sender] = false;
        --transactions[txIndex].confirmations;

        emit RevokeConfirmation(txIndex, msg.sender);
    }

    function executeTransaction(uint256 txIndex) external onlySigner {
        if (txIndex >= transactions.length) revert TxNotFound();
        if (transactions[txIndex].executed) revert AlreadyExecuted();
        if (transactions[txIndex].confirmations < requiredConfirmations) revert InsufficientConfirmations();

        Transaction storage txData = transactions[txIndex];
        txData.executed = true;

        uint256 value = txData.value;
        address to = txData.to;

        (bool success, ) = to.call{value: value}("");
        if (!success) revert ExecutionFailed();

        emit ExecuteTransaction(txIndex, to, value);
    }

    function getTransaction(uint256 txIndex) external view returns (
        address to,
        uint256 value,
        bool executed,
        uint256 confirmationsCount
    ) {
        if (txIndex >= transactions.length) revert TxNotFound();

        Transaction storage txData = transactions[txIndex];
        return (
            txData.to,
            txData.value,
            txData.executed,
            txData.confirmations
        );
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getSigners() external view returns (address[] memory) {
        return signers;
    }

    function hasConfirmed(uint256 txIndex, address signer) external view returns (bool) {
        if (txIndex >= transactions.length) revert TxNotFound();
        return confirmations[txIndex][signer];
    }

    function getRequiredConfirmations() external view returns (uint256) {
        return requiredConfirmations;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}