// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdvancedCrowdfunding {
    // 状态定义：创建 -> 众筹中 -> 成功/失败 -> 已提取/已退款
    enum State { Created, Fundraising, Success, Failed, PaidOut, Refunded }

    // 受益人结构
    struct Beneficiary {
        address addr;
        uint256 share;  // 份额（百分比 * 100）
    }

    // 贡献者信息
    struct Contributor {
        uint256 totalContributed;
        uint256 timestamp;
    }

    // 基础变量
    State public currentState;
    address public creator;
    uint256 public goal;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public deadline;
    uint256 public createdAt;
    uint256 public totalContributed;

    // 受益人列表
    Beneficiary[] public beneficiaries;
    // 贡献记录
    mapping(address => Contributor) public contributors;
    // 地址列表（用于遍历）
    address[] public contributorAddresses;

    event CampaignCreated(address indexed creator, uint256 goal, uint256 deadline);
    event ContributionReceived(address indexed contributor, uint256 amount, uint256 timestamp);
    event StateChanged(State from, State to);
    event FundWithdrawn(address indexed recipient, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    event BeneficiaryAdded(address indexed beneficiary, uint256 share);

    error NotCreator();
    error NotOwner();
    error InvalidStateTransition(State current, State target);
    error ContributionTooLow();
    error ContributionTooHigh();
    error ContributionNotInRange();
    error DeadlineNotPassed();
    error DeadlineAlreadyPassed();
    error GoalNotReached();
    error GoalAlreadyReached();
    error CampaignNotActive();
    error AlreadyContributed();
    error ZeroAmount();
    error InvalidShare();
    error SharesMustEqual100();
    error NothingToWithdraw();
    error NothingToRefund();

    modifier onlyCreator() {
        if (msg.sender != creator) revert NotCreator();
        _;
    }

    modifier inState(State state) {
        if (currentState != state) revert InvalidStateTransition(currentState, state);
        _;
    }

    modifier onlyInStates(State[] memory states) {
        bool validState = false;
        for (uint256 i = 0; i < states.length; i++) {
            if (currentState == states[i]) {
                validState = true;
                break;
            }
        }
        if (!validState) revert InvalidStateTransition(currentState, currentState);
        _;
    }

    constructor(
        uint256 _goal,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _duration
    ) {
        if (_goal == 0) revert ZeroAmount();
        if (_minContribution == 0) revert ZeroAmount();
        if (_maxContribution < _minContribution) revert ContributionTooLow();

        creator = msg.sender;
        goal = _goal;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        deadline = block.timestamp + _duration;
        createdAt = block.timestamp;
        currentState = State.Created;
        totalContributed = 0;

        emit CampaignCreated(creator, goal, deadline);
    }

    // 启动众筹
    function startFundraising() external onlyCreator inState(State.Created) {
        if (beneficiaries.length == 0) revert ZeroAmount();
        _transitionTo(State.Fundraising);
    }

    // 添加受益人
    function addBeneficiary(address _addr, uint256 _share) external onlyCreator inState(State.Created) {
        if (_addr == address(0)) revert ZeroAmount();
        if (_share == 0) revert InvalidShare();

        beneficiaries.push(Beneficiary({
            addr: _addr,
            share: _share
        }));

        emit BeneficiaryAdded(_addr, _share);
    }

    // 设置受益人份额（确保总和为10000）
    function finalizeBeneficiaries() external onlyCreator inState(State.Created) {
        uint256 totalShare;
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            totalShare += beneficiaries[i].share;
        }
        if (totalShare != 10000) revert SharesMustEqual100();

        _transitionTo(State.Fundraising);
    }

    // 贡献 ETH
    function contribute() external payable onlyInStates(_getFundraisingStates()) {
        if (msg.value < minContribution) revert ContributionTooLow();
        if (msg.value > maxContribution) revert ContributionTooHigh();
        if (block.timestamp >= deadline) revert DeadlineAlreadyPassed();

        Contributor storage contributor = contributors[msg.sender];
        uint256 newTotal = contributor.totalContributed + msg.value;
        if (newTotal > maxContribution) revert ContributionTooHigh();

        if (contributor.totalContributed == 0) {
            contributorAddresses.push(msg.sender);
        }

        contributor.totalContributed = newTotal;
        contributor.timestamp = block.timestamp;
        totalContributed += msg.value;

        emit ContributionReceived(msg.sender, msg.value, block.timestamp);

        // 自动检查目标达成
        if (totalContributed >= goal) {
            _transitionTo(State.Success);
        }
    }

    // 检查并结束众筹
    function finalizeCampaign() external inState(State.Fundraising) {
        if (block.timestamp < deadline) revert DeadlineNotPassed();

        if (totalContributed >= goal) {
            _transitionTo(State.Success);
        } else {
            _transitionTo(State.Failed);
        }
    }

    // 提取资金（按份额分配）
    function withdraw() external inState(State.Success) {
        if (address(this).balance == 0) revert NothingToWithdraw();

        uint256 contractBalance = address(this).balance;

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            Beneficiary storage b = beneficiaries[i];
            uint256 amount = (contractBalance * b.share) / 10000;
            if (amount > 0) {
                emit FundWithdrawn(b.addr, amount);
                (bool success, ) = payable(b.addr).call{value: amount}("");
                require(success, "Transfer failed");
            }
        }

        _transitionTo(State.PaidOut);
    }

    // 认领退款
    function claimRefund() external inState(State.Failed) {
        Contributor storage contributor = contributors[msg.sender];
        if (contributor.totalContributed == 0) revert NothingToRefund();

        uint256 amount = contributor.totalContributed;
        contributor.totalContributed = 0;

        emit RefundClaimed(msg.sender, amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        if (_allRefunded()) {
            _transitionTo(State.Refunded);
        }
    }

    // 查询函数
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContributorCount() external view returns (uint256) {
        return contributorAddresses.length;
    }

    function getContributor(address _addr) external view returns (uint256 contributed, uint256 contribTimestamp) {
        Contributor memory c = contributors[_addr];
        return (c.totalContributed, c.timestamp);
    }

    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    function getBeneficiaryCount() external view returns (uint256) {
        return beneficiaries.length;
    }

    function getProgress() external view returns (uint256 percentage) {
        if (goal == 0) return 0;
        return (totalContributed * 100) / goal;
    }

    // 内部函数
    function _transitionTo(State newState) internal {
        State oldState = currentState;
        currentState = newState;
        emit StateChanged(oldState, newState);
    }

    function _allRefunded() internal view returns (bool) {
        for (uint256 i = 0; i < contributorAddresses.length; i++) {
            if (contributors[contributorAddresses[i]].totalContributed > 0) {
                return false;
            }
        }
        return true;
    }

    function _getFundraisingStates() internal pure returns (State[] memory) {
        State[] memory states = new State[](2);
        states[0] = State.Created;
        states[1] = State.Fundraising;
        return states;
    }
}