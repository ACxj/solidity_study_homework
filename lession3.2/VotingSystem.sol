// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    string public votingTitle;
    uint256 public votingEndTime;
    bool public votingStarted;

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        mapping(address => bool) voters;
    }

    Proposal[] private proposals;
    mapping(address => bool) private proposalCreators;

    error VotingEnded();
    error ProposalNotFound(uint256 id);
    error AlreadyVoted(address voter, uint256 proposalId);
    error AlreadyCreatedProposal();

    event ProposalCreated(uint256 indexed id, address indexed creator, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter);

    constructor(string memory title, uint256 duration) {
        votingTitle = title;
        votingEndTime = block.timestamp + duration;
        votingStarted = true;
    }

    function createProposal(string memory description) external returns (uint256) {
        if (block.timestamp >= votingEndTime) revert VotingEnded();
        if (proposalCreators[msg.sender]) revert AlreadyCreatedProposal();

        uint256 proposalId = proposals.length;

        Proposal storage newProposal = proposals.push();
        newProposal.id = proposalId;
        newProposal.description = description;
        newProposal.voteCount = 0;
        proposalCreators[msg.sender] = true;

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    function vote(uint256 proposalId) external {
        if (block.timestamp >= votingEndTime) revert VotingEnded();
        if (proposalId >= proposals.length) revert ProposalNotFound(proposalId);

        Proposal storage proposal = proposals[proposalId];
        if (proposal.voters[msg.sender]) revert AlreadyVoted(msg.sender, proposalId);

        proposal.voters[msg.sender] = true;
        ++proposal.voteCount;

        emit VoteCast(proposalId, msg.sender);
    }

    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        string memory description,
        uint256 voteCount,
        bool userHasVoted
    ) {
        if (proposalId >= proposals.length) revert ProposalNotFound(proposalId);

        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.voteCount,
            proposal.voters[msg.sender]
        );
    }

    function getWinningProposal() external view returns (uint256 winningId, string memory description, uint256 voteCount) {
        if (proposals.length == 0) revert ProposalNotFound(0);

        uint256 maxVotes;
        uint256 winner;

        uint256 len = proposals.length;
        for (uint256 i = 0; i < len; ++i) {
            if (proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winner = i;
            }
        }

        return (winner, proposals[winner].description, maxVotes);
    }

    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        if (proposalId >= proposals.length) revert ProposalNotFound(proposalId);
        return proposals[proposalId].voters[voter];
    }

    function isVotingActive() external view returns (bool) {
        return block.timestamp < votingEndTime;
    }

    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= votingEndTime) return 0;
        return votingEndTime - block.timestamp;
    }
}