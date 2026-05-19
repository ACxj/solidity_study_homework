// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorageLayout.sol";

contract ImplementationV1 is StorageLayout {
    event ValueStored(bytes32 indexed key, uint256 value);
    event Incremented(bytes32 indexed key, uint256 oldValue, uint256 newValue);

    error Unauthorized();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    function initialize(address _admin) external {
        require(admin == address(0), "Already initialized");
        admin = _admin;
        implementation = address(this);
        version = 1;
    }

    function storeValue(bytes32 key, uint256 value) external onlyAdmin {
        uintStorage[key] = value;
        emit ValueStored(key, value);
    }

    function getValue(bytes32 key) external view returns (uint256) {
        return uintStorage[key];
    }

    function incrementValue(bytes32 key) external returns (uint256 oldValue, uint256 newValue) {
        oldValue = uintStorage[key];
        newValue = oldValue + 1;
        uintStorage[key] = newValue;
        emit Incremented(key, oldValue, newValue);
    }
}
