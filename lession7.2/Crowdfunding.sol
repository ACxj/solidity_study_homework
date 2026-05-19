// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Crowdfunding {
    enum State { Fundraising, Succeeded, Failed, PaidOut, Refunding }

    struct Campaign {
        address creator;
        uint256 goal;
        uint256 deadline;
        uint256 totalContributed;
        uint256 minContribution;
        uint256 maxContribution;
        State state;
    }

    struct Contribution {
        uint256 amount;
        uint256 timestamp;
        bool refunded;
    }

    Campaign public campaign;
    mapping(address => Contribution) public contributions;
    address[] private contributorList;

    event CampaignCreated(address indexed creator, uint256 goal, uint256 deadline);
    event Contributed(address indexed contributor, uint256 amount);
    event CampaignSucceeded(uint256 totalRaised);
    event CampaignFailed(uint256 totalRaised);
    event FundPaidOut(address indexed creator, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    event RefundFailed(address indexed contributor, string reason);

    error CampaignNotInFundraisingState();
    error CampaignEnded();
    error ContributionTooLow(uint256 min, uint256 actual);
    error ContributionTooHigh(uint256 max, uint256 actual);
    error ContributionExceedsLimit(address contributor, uint256 limit, uint256 attempted);
    error DeadlineNotPassed();
    error GoalNotReached();
    error GoalAlreadyReached();
    error NothingToRefund();
    error AlreadyRefunded();
    error TransferFailed(address to, uint256 amount);
    error InvalidGoal();
    error InvalidDeadline();
    error InvalidContributionRange();

    modifier onlyInState(State state) {
        if (campaign.state != state) revert CampaignNotInFundraisingState();
        _;
    }

    modifier onlyCreator() {
        if (msg.sender != campaign.creator) revert CampaignNotInFundraisingState();
        _;
    }

    modifier onlyAfterDeadline() {
        if (block.timestamp < campaign.deadline) revert DeadlineNotPassed();
        _;
    }

    constructor(
        uint256 _goal,
        uint256 _duration,
        uint256 _minContribution,
        uint256 _maxContribution
    ) {
        if (_goal == 0) revert InvalidGoal();
        if (_duration == 0) revert InvalidDeadline();
        if (_minContribution == 0 || _maxContribution == 0) revert InvalidContributionRange();
        if (_maxContribution < _minContribution) revert InvalidContributionRange();

        campaign = Campaign({
            creator: msg.sender,
            goal: _goal,
            deadline: block.timestamp + _duration,
            totalContributed: 0,
            minContribution: _minContribution,
            maxContribution: _maxContribution,
            state: State.Fundraising
        });

        emit CampaignCreated(msg.sender, _goal, campaign.deadline);
    }

    function contribute() external payable onlyInState(State.Fundraising) {
        if (msg.value < campaign.minContribution) {
            revert ContributionTooLow(campaign.minContribution, msg.value);
        }
        if (msg.value > campaign.maxContribution) {
            revert ContributionTooHigh(campaign.maxContribution, msg.value);
        }

        uint256 newTotal = contributions[msg.sender].amount + msg.value;
        if (newTotal > campaign.maxContribution) {
            revert ContributionExceedsLimit(msg.sender, campaign.maxContribution, newTotal);
        }

        Contribution storage contribution = contributions[msg.sender];

        if (contribution.amount == 0) {
            contributorList.push(msg.sender);
            contribution.timestamp = block.timestamp;
        }
        contribution.amount = newTotal;
        campaign.totalContributed += msg.value;

        emit Contributed(msg.sender, msg.value);

        if (campaign.totalContributed >= campaign.goal) {
            campaign.state = State.Succeeded;
            emit CampaignSucceeded(campaign.totalContributed);
        }
    }

    function finalizeCampaign() external onlyCreator onlyInState(State.Fundraising) onlyAfterDeadline {
        if (campaign.totalContributed >= campaign.goal) {
            campaign.state = State.Succeeded;
            emit CampaignSucceeded(campaign.totalContributed);
        } else {
            campaign.state = State.Failed;
            emit CampaignFailed(campaign.totalContributed);
        }
    }

    function claimRefund() external onlyInState(State.Failed) {
        Contribution storage contribution = contributions[msg.sender];

        if (contribution.amount == 0) revert NothingToRefund();
        if (contribution.refunded) revert AlreadyRefunded();

        uint256 refundAmount = contribution.amount;
        contribution.refunded = true;

        emit RefundClaimed(msg.sender, refundAmount);

        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        if (!success) {
            contribution.refunded = false;
            emit RefundFailed(msg.sender, "Transfer call failed");
            revert TransferFailed(msg.sender, refundAmount);
        }
    }

    function batchRefund() external onlyCreator onlyInState(State.Failed) onlyAfterDeadline {
        uint256 failedCount = 0;
        uint256 successCount = 0;

        for (uint256 i = 0; i < contributorList.length; i++) {
            address contributor = contributorList[i];
            Contribution storage contribution = contributions[contributor];

            if (contribution.amount > 0 && !contribution.refunded) {
                uint256 refundAmount = contribution.amount;
                contribution.refunded = true;

                (bool success, ) = payable(contributor).call{value: refundAmount}("");

                if (success) {
                    successCount++;
                } else {
                    contribution.refunded = false;
                    failedCount++;
                    emit RefundFailed(contributor, "Batch refund failed");
                }
            }
        }

        require(failedCount == 0, "Some refunds failed");
    }

    function withdrawFunds() external onlyCreator onlyInState(State.Succeeded) {
        uint256 amount = address(this).balance;

        emit FundPaidOut(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed(msg.sender, amount);
        }

        campaign.state = State.PaidOut;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContributorCount() external view returns (uint256) {
        return contributorList.length;
    }

    function getContribution(address contributor) external view returns (uint256 amount, bool refunded) {
        return (contributions[contributor].amount, contributions[contributor].refunded);
    }

    function getCampaignProgress() external view returns (uint256 raised, uint256 goal, uint256 percentage) {
        raised = campaign.totalContributed;
        goal = campaign.goal;
        percentage = goal > 0 ? (raised * 100) / goal : 0;
    }

    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= campaign.deadline) return 0;
        return campaign.deadline - block.timestamp;
    }
}