// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorageLayout.sol";

contract ProxyContract is StorageLayout {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    error InvalidImplementation();
    error InvalidAdmin();
    error NotProxy();

    constructor(address _implementation, address _admin) {
        if (_implementation == address(0)) revert InvalidImplementation();
        if (_admin == address(0)) revert InvalidAdmin();

        implementation = _implementation;
        admin = _admin;
    }

    fallback() external payable {
        address target = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

    function upgradeTo(address newImplementation) external {
        if (msg.sender != admin) revert Unauthorized();
        if (newImplementation == address(0)) revert InvalidImplementation();

        address oldImplementation = implementation;
        implementation = newImplementation;

        emit Upgraded(oldImplementation, newImplementation);
    }

    function changeAdmin(address newAdmin) external {
        if (msg.sender != admin) revert Unauthorized();
        if (newAdmin == address(0)) revert InvalidAdmin();

        address oldAdmin = admin;
        admin = newAdmin;

        emit AdminChanged(oldAdmin, newAdmin);
    }
}

contract ProxyAdmin {
    address public proxy;
    address public implementation;

    event ProxyCreated(address proxy);
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    error NotProxy();

    constructor(address _implementation) {
        implementation = _implementation;
        proxy = address(new ProxyContract(_implementation, msg.sender));
        emit ProxyCreated(proxy);
    }

    function upgrade(address newImplementation) external {
        ProxyContract(payable(proxy)).upgradeTo(newImplementation);
        implementation = newImplementation;
        emit Upgraded(implementation, newImplementation);
    }

    function getProxyAdmin() external view returns (address) {
        return ProxyContract(payable(proxy)).admin();
    }

    function getImplementation() external view returns (address) {
        return ProxyContract(payable(proxy)).implementation();
    }
}
