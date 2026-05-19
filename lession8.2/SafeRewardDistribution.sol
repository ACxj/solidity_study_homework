// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeRewardDistribution {
    uint256 public constant BATCH_SIZE = 100;
    uint256 public constant CLAIM_TIMEOUT = 30 days;

    address public admin;
    uint256 public distributionId;
    uint256 public totalRewards;
    uint256 public claimedRewards;
    uint256 public deadline;
    bool public finalized;

    mapping(uint256 => Reward) public rewards;
    mapping(address => mapping(uint256 => uint256)) public pendingRewards;
    mapping(uint256 => mapping(address => bool)) public claimed;

    struct Reward {
        address recipient;
        uint256 amount;
        uint256 claimableAt;
    }

    event RewardAdded(uint256 indexed distributionId, address indexed recipient, uint256 amount);
    event RewardClaimed(uint256 indexed distributionId, address indexed recipient, uint256 amount);
    event RewardsDistributed(uint256 indexed distributionId, uint256 totalAmount, uint256 recipientCount);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event EmergencyWithdraw(address indexed admin, uint256 amount);

    error NotAdmin();
    error AlreadyFinalized();
    error NotFinalized();
    error DeadlinePassed();
    error NothingToClaim();
    error AlreadyClaimed();
    error BatchSizeExceeded(uint256 requested, uint256 max);
    error TransferFailed();
    error ZeroAmount();
    error ReentrancyBlocked();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    bool private reentrancyLock;

    modifier noReentrancy() {
        if (reentrancyLock) revert ReentrancyBlocked();
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor() {
        admin = msg.sender;
    }

    function addRewards(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyAdmin
    {
        if (recipients.length != amounts.length) revert ZeroAmount();
        if (recipients.length > BATCH_SIZE) {
            revert BatchSizeExceeded(recipients.length, BATCH_SIZE);
        }

        uint256 id = distributionId++;
        uint256 total;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert ZeroAmount();
            if (amounts[i] == 0) revert ZeroAmount();

            pendingRewards[recipients[i]][id] += amounts[i];
            total += amounts[i];

            emit RewardAdded(id, recipients[i], amounts[i]);
        }

        rewards[id] = Reward({
            recipient: address(0),
            amount: total,
            claimableAt: block.timestamp
        });

        totalRewards += total;
    }

    function claimReward(uint256 id) external noReentrancy {
        if (finalized) revert AlreadyFinalized();
        if (pendingRewards[msg.sender][id] == 0) revert NothingToClaim();
        if (claimed[id][msg.sender]) revert AlreadyClaimed();

        uint256 amount = pendingRewards[msg.sender][id];
        claimed[id][msg.sender] = true;
        claimedRewards += amount;

        emit RewardClaimed(id, msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function claimRewardsBatch(uint256 id, address[] calldata recipients)
        external
        onlyAdmin
        noReentrancy
    {
        if (recipients.length > BATCH_SIZE) {
            revert BatchSizeExceeded(recipients.length, BATCH_SIZE);
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = pendingRewards[recipient][id];

            if (amount > 0 && !claimed[id][recipient]) {
                claimed[id][recipient] = true;
                claimedRewards += amount;

                emit RewardClaimed(id, recipient, amount);

                (bool success, ) = payable(recipient).call{value: amount}("");
                if (!success) {
                    claimed[id][recipient] = false;
                    claimedRewards -= amount;
                    revert TransferFailed();
                }
            }
        }
    }

    function claimAllRewards() external noReentrancy {
        if (finalized) revert AlreadyFinalized();

        uint256 total;
        uint256 currentId = distributionId;

        for (uint256 id = 0; id < currentId; id++) {
            uint256 amount = pendingRewards[msg.sender][id];
            if (amount > 0 && !claimed[id][msg.sender]) {
                claimed[id][msg.sender] = true;
                claimedRewards += amount;
                total += amount;

                emit RewardClaimed(id, msg.sender, amount);
            }
        }

        if (total == 0) revert NothingToClaim();

        (bool success, ) = payable(msg.sender).call{value: total}("");
        if (!success) revert TransferFailed();
    }

    function finalizeDistribution() external onlyAdmin {
        if (finalized) revert AlreadyFinalized();
        finalized = true;
        deadline = block.timestamp + CLAIM_TIMEOUT;
    }

    function emergencyWithdraw() external onlyAdmin {
        if (!finalized) revert NotFinalized();
        if (block.timestamp < deadline) revert DeadlinePassed();

        uint256 unclaimed = totalRewards - claimedRewards;
        if (unclaimed == 0) revert NothingToClaim();

        emit EmergencyWithdraw(admin, unclaimed);

        (bool success, ) = payable(admin).call{value: unclaimed}("");
        if (!success) revert TransferFailed();
    }

    function getPendingReward(address recipient) external view returns (uint256) {
        uint256 total;
        uint256 currentId = distributionId;

        for (uint256 id = 0; id < currentId; id++) {
            if (!claimed[id][recipient]) {
                total += pendingRewards[recipient][id];
            }
        }
        return total;
    }

    function getUnclaimedCount() external view returns (uint256) {
        return distributionId;
    }

    function getClaimStatus(address recipient, uint256 id) external view returns (bool) {
        return claimed[id][recipient];
    }

    receive() external payable {}
}