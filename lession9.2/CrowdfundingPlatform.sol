// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CrowdfundingPlatform {
    // 众筹状态机
    enum CampaignState { Created, Active, Ended, Completed, Cancelled }

    // 单个众筹活动结构
    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goal;
        uint256 raised;
        uint256 startTime;
        uint256 endTime;
        uint256 durationDays;
        CampaignState state;
        uint256 minContribution;
        bool exists;
    }

    // 用户贡献记录
    struct Contribution {
        uint256 amount;
        uint256 timestamp;
    }

    // 活动ID到活动信息的映射
    mapping(uint256 => Campaign) public campaigns;

    // 活动贡献者记录: campaignId -> user -> Contribution
    mapping(uint256 => mapping(address => Contribution)) public contributions;

    // 活动贡献者列表（用于遍历）
    mapping(uint256 => address[]) public contributorLists;

    // 全局活动计数器
    uint256 public campaignCount;

    // 暂停标志
    bool public paused;

    // 紧急停止标志
    bool public emergencyStopped;

    // owner
    address public owner;

    // 事件
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goal
    );
    event CampaignStarted(uint256 indexed campaignId, uint256 startTime, uint256 endTime);
    event DonationReceived(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount,
        uint256 total
    );
    event CampaignEnded(uint256 indexed campaignId, uint256 totalRaised, bool goalReached);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed creator, uint256 amount);
    event RefundClaimed(uint256 indexed campaignId, address indexed donor, uint256 amount);
    event CampaignCancelled(uint256 indexed campaignId);
    event Paused();
    event Unpaused();
    event EmergencyStopped();
    event EmergencyResumed();

    // 错误
    error CampaignNotFound();
    error InvalidState();
    error InvalidGoal();
    error InvalidTimeframe();
    error GoalNotReached();
    error NothingToRefund();
    error OnlyOwner();
    error PausedError();
    error EmergencyStoppedError();

    // 修饰器
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert PausedError();
        _;
    }

    modifier notEmergencyStopped() {
        if (emergencyStopped) revert EmergencyStoppedError();
        _;
    }

    modifier inCampaignState(uint256 campaignId, CampaignState expected) {
        if (!campaigns[campaignId].exists) revert CampaignNotFound();
        if (campaigns[campaignId].state != expected) revert InvalidState();
        _;
    }

    // 构造函数
    constructor() {
        owner = msg.sender;
        paused = false;
        emergencyStopped = false;
    }

    // 暂停
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    // 恢复
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    // 紧急停止
    function emergencyStop() external onlyOwner {
        emergencyStopped = true;
        emit EmergencyStopped();
    }

    // 恢复紧急停止
    function resumeFromEmergency() external onlyOwner {
        emergencyStopped = false;
        emit EmergencyResumed();
    }

    // 创建众筹活动
    function createCampaign(
        string calldata title,
        string calldata description,
        uint256 goal,
        uint256 durationDays,
        uint256 minContribution
    ) external whenNotPaused notEmergencyStopped returns (uint256) {
        if (goal == 0) revert InvalidGoal();
        if (durationDays == 0 || durationDays > 365) revert InvalidTimeframe();

        uint256 campaignId = campaignCount++;

        campaigns[campaignId] = Campaign({
            creator: msg.sender,
            title: title,
            description: description,
            goal: goal,
            raised: 0,
            startTime: 0,
            endTime: 0,
            durationDays: durationDays,
            state: CampaignState.Created,
            minContribution: minContribution,
            exists: true
        });

        emit CampaignCreated(campaignId, msg.sender, title, goal);

        return campaignId;
    }

    // 启动众筹活动
    function startCampaign(uint256 campaignId)
        external
        notEmergencyStopped
        inCampaignState(campaignId, CampaignState.Created)
    {
        Campaign storage campaign = campaigns[campaignId];
        if (msg.sender != campaign.creator) revert InvalidState();

        campaign.state = CampaignState.Active;
        campaign.startTime = block.timestamp;
        campaign.endTime = block.timestamp + (campaign.durationDays * 1 days);

        emit CampaignStarted(campaignId, campaign.startTime, campaign.endTime);
    }

    // 捐赠
    function donate(uint256 campaignId)
        external
        payable
        whenNotPaused
        notEmergencyStopped
        inCampaignState(campaignId, CampaignState.Active)
    {
        Campaign storage campaign = campaigns[campaignId];

        if (block.timestamp > campaign.endTime) {
            campaign.state = CampaignState.Ended;
            revert InvalidState();
        }

        if (msg.value < campaign.minContribution) revert InvalidState();

        Contribution storage contribution = contributions[campaignId][msg.sender];

        if (contribution.amount == 0) {
            contributorLists[campaignId].push(msg.sender);
        }

        contribution.amount += msg.value;
        contribution.timestamp = block.timestamp;

        campaign.raised += msg.value;

        emit DonationReceived(campaignId, msg.sender, msg.value, campaign.raised);
    }

    // 结束众筹
    function endCampaign(uint256 campaignId)
        external
        inCampaignState(campaignId, CampaignState.Active)
    {
        Campaign storage campaign = campaigns[campaignId];

        if (block.timestamp < campaign.endTime) {
            revert InvalidTimeframe();
        }

        campaign.state = CampaignState.Ended;

        bool goalReached = campaign.raised >= campaign.goal;
        emit CampaignEnded(campaignId, campaign.raised, goalReached);
    }

    // 创建者提取资金
    function withdrawFunds(uint256 campaignId)
        external
        inCampaignState(campaignId, CampaignState.Ended)
        returns (uint256)
    {
        Campaign storage campaign = campaigns[campaignId];

        if (msg.sender != campaign.creator) revert InvalidState();
        if (campaign.raised < campaign.goal) revert GoalNotReached();

        uint256 amount = campaign.raised;
        campaign.raised = 0;
        campaign.state = CampaignState.Completed;

        (bool success, ) = payable(campaign.creator).call{value: amount}("");
        if (!success) {
            campaign.raised = amount;
            revert InvalidState();
        }

        emit FundsWithdrawn(campaignId, campaign.creator, amount);

        return amount;
    }

    // 捐赠者退款
    function claimRefund(uint256 campaignId)
        external
        inCampaignState(campaignId, CampaignState.Ended)
        returns (uint256)
    {
        Campaign storage campaign = campaigns[campaignId];

        if (campaign.raised >= campaign.goal) revert GoalNotReached();

        Contribution storage contribution = contributions[campaignId][msg.sender];
        if (contribution.amount == 0) revert NothingToRefund();

        uint256 amount = contribution.amount;
        contribution.amount = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            contribution.amount = amount;
            revert InvalidState();
        }

        emit RefundClaimed(campaignId, msg.sender, amount);

        return amount;
    }

    // 取消众筹
    function cancelCampaign(uint256 campaignId)
        external
        inCampaignState(campaignId, CampaignState.Created)
    {
        Campaign storage campaign = campaigns[campaignId];

        if (msg.sender != campaign.creator) revert InvalidState();

        campaign.state = CampaignState.Cancelled;

        emit CampaignCancelled(campaignId);
    }

    // 查询函数
    function getCampaign(uint256 campaignId) external view returns (Campaign memory) {
        if (!campaigns[campaignId].exists) revert CampaignNotFound();
        return campaigns[campaignId];
    }

    function getContribution(uint256 campaignId, address donor) external view returns (uint256) {
        return contributions[campaignId][donor].amount;
    }

    function getContributorCount(uint256 campaignId) external view returns (uint256) {
        return contributorLists[campaignId].length;
    }
}
