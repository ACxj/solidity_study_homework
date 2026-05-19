// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuctionStateMachine {
    // 状态枚举：拍卖的生命周期
    // Created   → 拍卖已创建，等待开始
    // Active    → 拍卖进行中，接受出价
    // Ended     → 拍卖已结束，领取代币/提取
    // Completed → 拍卖完成，物品已交付
    enum State { Created, Active, Ended, Completed }

    State public state;
    address public owner;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    uint256 public constant BIDDING_DURATION = 1 minutes;

    // 记录每个地址的总出价金额
    mapping(address => uint256) public bids;

    event AuctionCreated(uint256 startTime);
    event BidPlaced(address bidder, uint256 amount, uint256 totalBid);
    event AuctionEnded(address winner, uint256 winningBid);
    event Withdrawn(address bidder, uint256 amount);
    event AuctionCompleted();

    error InvalidState(State current);
    error OnlyOwner();
    error BidTooLow(uint256 bid, uint256 highestBid);
    error AuctionNotEnded();
    error AuctionAlreadyEnded();
    error TransferFailed();
    error ZeroAmount();

    // 修饰器：确保只有 owner 可以调用
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    // 修饰器：确保当前状态符合预期
    modifier inState(State expected) {
        if (state != expected) revert InvalidState(state);
        _;
    }

    // 构造函数：初始化状态为 Created
    constructor() {
        owner = msg.sender;
        state = State.Created;
    }

    // 启动拍卖：只有 owner 可以调用，状态必须为 Created
    function startAuction() external onlyOwner inState(State.Created) {
        state = State.Active;
        auctionEndTime = block.timestamp + BIDDING_DURATION;
        emit AuctionCreated(block.timestamp);
    }

    // 出价：状态必须为 Active，出价必须大于当前最高出价
    function placeBid() external payable inState(State.Active) {
        // 检查拍卖是否已过期
        if (block.timestamp > auctionEndTime) revert AuctionAlreadyEnded();
        if (msg.value == 0) revert ZeroAmount();

        // 计算该用户的新总出价（之前出过 + 本次新出）
        uint256 newTotalBid = bids[msg.sender] + msg.value;

        // 新总出价必须高于当前最高
        if (newTotalBid <= highestBid) {
            revert BidTooLow(newTotalBid, highestBid);
        }

        // 更新用户的总出价
        bids[msg.sender] = newTotalBid;

        // 如果是新的最高出价，更新记录
        if (newTotalBid > highestBid) {
            highestBid = newTotalBid;
            highestBidder = msg.sender;
        }

        emit BidPlaced(msg.sender, msg.value, newTotalBid);
    }

    // 结束拍卖：只有 owner 可以调用，必须在拍卖时间到期后才能调用
    function endAuction() external onlyOwner inState(State.Active) {
        if (block.timestamp < auctionEndTime) revert AuctionNotEnded();

        state = State.Ended;
        emit AuctionEnded(highestBidder, highestBid);
    }

    // 提取出价：拍卖结束后，非胜出者可以提取已出的资金
    // 使用 CEI 模式防止重入
    function withdraw() external inState(State.Ended) returns (uint256) {
        // 胜出者不能提取，因为出价已经被 claimItem 转给 owner 了
        if (msg.sender == highestBidder) revert InvalidState(state);

        uint256 amount = bids[msg.sender];
        if (amount == 0) return 0;

        // 先清零，后转账（CEI 模式）
        bids[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // 转账失败时恢复余额
            bids[msg.sender] = amount;
            revert TransferFailed();
        }

        emit Withdrawn(msg.sender, amount);
        return amount;
    }

    // 领取物品：拍卖结束后，owner 可以领取最高出价金额
    function claimItem() external onlyOwner inState(State.Ended) {
        if (highestBidder == address(0)) revert InvalidState(state);

        state = State.Completed;
        emit AuctionCompleted();

        (bool success, ) = payable(owner).call{value: highestBid}("");
        if (!success) revert TransferFailed();
    }

    // 查询当前用户的总出价
    function getMyTotalBid() external view returns (uint256) {
        return bids[msg.sender];
    }

    // 查询拍卖状态信息
    function getAuctionInfo() external view returns (
        State currentState,
        address currentHighestBidder,
        uint256 currentHighestBid,
        uint256 timeRemaining
    ) {
        currentState = state;
        currentHighestBidder = highestBidder;
        currentHighestBid = highestBid;
        // 计算剩余时间（仅在 Active 状态有效）
        timeRemaining = (state == State.Active && auctionEndTime > block.timestamp)
            ? auctionEndTime - block.timestamp
            : 0;
    }
}
