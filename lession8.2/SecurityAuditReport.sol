// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SecurityChecklist {
    uint256 constant HIGH = 3;
    uint256 constant MEDIUM = 2;
    uint256 constant LOW = 1;

    struct Finding {
        string title;
        string description;
        string location;
        uint256 severity;
        string recommendation;
    }
}

contract SecurityAuditReport {
    using SecurityChecklist for SecurityChecklist.Finding;

    SecurityChecklist.Finding[] public findings;

    constructor() {
        findings.push(SecurityChecklist.Finding({
            title: "Reentrancy - claimRefund",
            description: "transfer may fail under Gas limit but balance is already zeroed",
            location: "claimRefund(), line 52",
            severity: SecurityChecklist.HIGH,
            recommendation: "Use CEI pattern or reentrancy lock"
        }));

        findings.push(SecurityChecklist.Finding({
            title: "Missing reentrancy lock - receive",
            description: "receive modifies state before transfer, no reentrancy protection",
            location: "receive(), line 86-92",
            severity: SecurityChecklist.HIGH,
            recommendation: "Add reentrancyGuard or CEI pattern"
        }));

        findings.push(SecurityChecklist.Finding({
            title: "Owner change logic flaw",
            description: "changeOwner can be called by anyone to set any newOwner",
            location: "changeOwner(), line 68-71",
            severity: SecurityChecklist.HIGH,
            recommendation: "Add onlyOwner modifier"
        }));

        findings.push(SecurityChecklist.Finding({
            title: "acceptOwnership event log error",
            description: "Event records new owner instead of old",
            location: "acceptOwnership(), line 77",
            severity: SecurityChecklist.LOW,
            recommendation: "emit OwnerChanged(oldOwner, newOwner)"
        }));

        findings.push(SecurityChecklist.Finding({
            title: "Integer overflow - raisedAmount",
            description: "raisedAmount += msg.value may overflow",
            location: "receive(), line 90",
            severity: SecurityChecklist.MEDIUM,
            recommendation: "Solidity 0.8+ auto checks, but explicit validation recommended"
        }));

        findings.push(SecurityChecklist.Finding({
            title: "DoS - infinite loop traversal",
            description: "addToWhitelist infinite loop may cause gas exhaustion",
            location: "addToWhitelist(), line 40-44",
            severity: SecurityChecklist.MEDIUM,
            recommendation: "Add batch size limit"
        }));

        findings.push(SecurityChecklist.Finding({
            title: "DoS - withdraw batch transfer",
            description: "If any contributor transfer fails, entire withdraw fails",
            location: "withdraw(), line 80",
            severity: SecurityChecklist.MEDIUM,
            recommendation: "Use Pull pattern"
        }));

        findings.push(SecurityChecklist.Finding({
            title: "Missing event logging",
            description: "addToWhitelist does not emit event",
            location: "addToWhitelist(), line 37-44",
            severity: SecurityChecklist.LOW,
            recommendation: "Add WhitelistUpdated event"
        }));
    }

    function getFindingsCount() external view returns (uint256) {
        return findings.length;
    }

    function getHighSeverityCount() external view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < findings.length; i++) {
            if (findings[i].severity == SecurityChecklist.HIGH) count++;
        }
        return count;
    }

    function getMediumSeverityCount() external view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < findings.length; i++) {
            if (findings[i].severity == SecurityChecklist.MEDIUM) count++;
        }
        return count;
    }

    function getLowSeverityCount() external view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < findings.length; i++) {
            if (findings[i].severity == SecurityChecklist.LOW) count++;
        }
        return count;
    }
}