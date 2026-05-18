// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    // 状态定义：Fundraising(众筹中), Success(成功), Failed(失败), PaidOut(已提取)
    enum State { Fundraising, Success, Failed, PaidOut }

    State public currentState;
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    mapping(address => uint256) public contributions;

    event Contributed(address indexed contributor, uint256 amount);
    event StateChanged(State from, State to);
    event FundWithdrawn(address indexed recipient, uint256 amount);

    // 错误定义
    error InvalidStateTransition(State current, State target);
    error NotOwner();
    error ContributionTooLow();
    error GoalNotReached();
    error GoalReached();
    error AlreadyPaidOut();
    error DeadlineNotPassed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier inState(State state) {
        if (currentState != state) revert InvalidStateTransition(currentState, state);
        _;
    }

    constructor(uint256 _goal, uint256 _duration) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
        currentState = State.Fundraising;
    }

    // 贡献 ETH
    function contribute() external payable inState(State.Fundraising) {
        if (msg.value == 0) revert ContributionTooLow();
        contributions[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    // 检查目标是否达成
    function checkGoalReached() external onlyOwner inState(State.Fundraising) {
        if (block.timestamp < deadline) revert DeadlineNotPassed();

        if (address(this).balance >= goal) {
            _transitionTo(State.Success);
        } else {
            _transitionTo(State.Failed);
        }
    }

    // 提取众筹资金
    function withdraw() external inState(State.Success) onlyOwner {
        _transitionTo(State.PaidOut);
        emit FundWithdrawn(owner, address(this).balance);
        payable(owner).transfer(address(this).balance);
    }

    // 认领退款
    function claimRefund() external inState(State.Failed) {
        uint256 contributed = contributions[msg.sender];
        if (contributed == 0) revert ContributionTooLow();

        contributions[msg.sender] = 0;
        emit FundWithdrawn(msg.sender, contributed);
        payable(msg.sender).transfer(contributed);
    }

    // 状态转换
    function _transitionTo(State newState) internal {
        if (newState <= currentState) revert InvalidStateTransition(currentState, newState);
        State oldState = currentState;
        currentState = newState;
        emit StateChanged(oldState, newState);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContribution(address contributor) external view returns (uint256) {
        return contributions[contributor];
    }
}