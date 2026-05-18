// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        uint256 deadline;
        mapping(address => bool) voters;
    }

    Proposal[] private proposals;
    address public owner;

    error NotOwner();
    error ProposalNotFound(uint256 id);
    error AlreadyVoted(uint256 proposalId);
    error VotingEnded(uint256 proposalId);
    error NoProposals();

    event ProposalCreated(uint256 indexed id, string description, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createProposal(string memory description, uint256 duration) external onlyOwner returns (uint256) {
        uint256 deadline = block.timestamp + duration;
        uint256 proposalId = proposals.length;

        Proposal storage newProposal = proposals.push();
        newProposal.id = proposalId;
        newProposal.description = description;
        newProposal.voteCount = 0;
        newProposal.deadline = deadline;

        emit ProposalCreated(proposalId, description, deadline);
        return proposalId;
    }

    function vote(uint256 proposalId) external {
        if (proposalId >= proposals.length) revert ProposalNotFound(proposalId);

        Proposal storage proposal = proposals[proposalId];
        if (block.timestamp >= proposal.deadline) revert VotingEnded(proposalId);
        if (proposal.voters[msg.sender]) revert AlreadyVoted(proposalId);

        proposal.voters[msg.sender] = true;
        ++proposal.voteCount;

        emit VoteCast(proposalId, msg.sender);
    }

    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        string memory description,
        uint256 voteCount,
        uint256 deadline,
        bool isActive,
        bool userHasVoted
    ) {
        if (proposalId >= proposals.length) revert ProposalNotFound(proposalId);

        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.voteCount,
            proposal.deadline,
            block.timestamp < proposal.deadline,
            proposal.voters[msg.sender]
        );
    }

    function getWinningProposal() external view returns (uint256 winningId, string memory description, uint256 voteCount) {
        if (proposals.length == 0) revert NoProposals();

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

    function getActiveProposals() external view returns (uint256[] memory activeIds) {
        uint256 count;
        uint256 len = proposals.length;
        for (uint256 i = 0; i < len; ++i) {
            if (block.timestamp < proposals[i].deadline) {
                ++count;
            }
        }

        activeIds = new uint256[](count);
        uint256 index;
        for (uint256 i = 0; i < len; ++i) {
            if (block.timestamp < proposals[i].deadline) {
                activeIds[index++] = i;
            }
        }
    }

    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        if (proposalId >= proposals.length) revert ProposalNotFound(proposalId);
        return proposals[proposalId].voters[voter];
    }
}