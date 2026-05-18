// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // 定义投票选项枚举
    enum VoteOption {
        Yes,
        No,
        Abstain
    }

    // 记录每个地址的投票
    mapping(address => VoteOption) public votes;

    // 记录每个地址是否已经投票
    mapping(address => bool) public hasVoted;

    // 统计每个选项的票数
    uint public yesVotes;
    uint public noVotes;
    uint public abstainVotes;

    // 投票事件
    event VoteCast(address indexed voter, VoteOption option);

    // 投票函数
    function vote(VoteOption _option) public {
        require(!hasVoted[msg.sender], "You have already voted");

        votes[msg.sender] = _option;
        hasVoted[msg.sender] = true;

        if (_option == VoteOption.Yes) {
            yesVotes++;
        } else if (_option == VoteOption.No) {
            noVotes++;
        } else if (_option == VoteOption.Abstain) {
            abstainVotes++;
        }

        emit VoteCast(msg.sender, _option);
    }

    // 查询某个地址的投票
    function getVote(address _voter) public view returns (VoteOption) {
        require(hasVoted[_voter], "This address has not voted yet");
        return votes[_voter];
    }

    // 查询所有投票结果
    function getResults() public view returns (uint _yes, uint _no, uint _abstain) {
        return (yesVotes, noVotes, abstainVotes);
    }

    // 查询总投票数
    function getTotalVotes() public view returns (uint) {
        return yesVotes + noVotes + abstainVotes;
    }
}
