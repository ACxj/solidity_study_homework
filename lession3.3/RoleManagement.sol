// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RoleManagement {
    enum Role { None, User, Admin, Owner }

    mapping(address => Role) private roles;

    error NotAuthorized();
    error InvalidRole();
    error AlreadyHasRole();
    error CannotDemoteOwner();
    error ZeroAddress();

    event RoleAssigned(address indexed account, Role role);
    event RoleRemoved(address indexed account);

    modifier onlyOwner() {
        if (roles[msg.sender] != Role.Owner) revert NotAuthorized();
        _;
    }

    modifier onlyAdmin() {
        if (roles[msg.sender] != Role.Owner && roles[msg.sender] != Role.Admin) revert NotAuthorized();
        _;
    }

    constructor() {
        roles[msg.sender] = Role.Owner;
        emit RoleAssigned(msg.sender, Role.Owner);
    }

    function assignAdmin(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        if (roles[account] == Role.Admin) revert AlreadyHasRole();
        if (roles[account] == Role.Owner) revert InvalidRole();

        roles[account] = Role.Admin;
        emit RoleAssigned(account, Role.Admin);
    }

    function assignUser(address account) external onlyAdmin {
        if (account == address(0)) revert ZeroAddress();
        if (roles[account] == Role.User) revert AlreadyHasRole();
        if (roles[account] == Role.Admin || roles[account] == Role.Owner) revert InvalidRole();

        roles[account] = Role.User;
        emit RoleAssigned(account, Role.User);
    }

    function removeRole(address account) external onlyAdmin {
        if (account == address(0)) revert ZeroAddress();
        if (roles[account] == Role.Owner) revert CannotDemoteOwner();
        if (roles[account] == Role.None) revert InvalidRole();

        roles[account] = Role.None;
        emit RoleRemoved(account);
    }

    function getRole(address account) external view returns (Role) {
        return roles[account];
    }

    function getMyRole() external view returns (Role) {
        return roles[msg.sender];
    }

    function isOwner(address account) external view returns (bool) {
        return roles[account] == Role.Owner;
    }

    function isAdmin(address account) external view returns (bool) {
        return roles[account] == Role.Admin;
    }

    function isUser(address account) external view returns (bool) {
        return roles[account] == Role.User;
    }
}