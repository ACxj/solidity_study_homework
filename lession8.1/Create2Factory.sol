// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {
    uint256 public value;
    address public creator;

    constructor(uint256 _value) {
        value = _value;
        creator = msg.sender;
    }
}

contract Create2Factory {
    mapping(address => mapping(bytes32 => address)) public deployedContracts;
    mapping(bytes32 => address) public saltToContract;

    event ContractDeployed(
        address indexed deployedAddress,
        bytes32 indexed salt,
        bytes bytecode,
        uint256 value
    );
    event AddressPrecomputed(
        address indexed precomputedAddress,
        bytes32 indexed salt,
        bytes32 bytecodeHash
    );

    error DeploymentFailed();
    error SaltAlreadyUsed(bytes32 salt);
    error AddressMismatch(address expected, address actual);
    error ZeroBytes();

    function getDeploymentAddress(
        address deployer,
        bytes32 salt,
        bytes memory bytecode
    ) public pure returns (address) {
        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                salt,
                bytecodeHash
            )
        );
        return address(uint160(uint256(hash)));
    }

    function precomputeAddress(
        bytes32 salt,
        bytes memory bytecode
    ) external returns (address) {
        if (bytecode.length == 0) revert ZeroBytes();

        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                bytecodeHash
            )
        );
        address precomputed = address(uint160(uint256(hash)));

        emit AddressPrecomputed(precomputed, salt, bytecodeHash);
        return precomputed;
    }

    function deploy(
        bytes32 salt,
        bytes memory bytecode,
        uint256 value
    ) external returns (address) {
        if (bytecode.length == 0) revert ZeroBytes();
        if (saltToContract[salt] != address(0)) revert SaltAlreadyUsed(salt);

        address expectedAddress = getDeploymentAddress(
            address(this),
            salt,
            bytecode
        );

        address deployed;
        assembly {
            deployed := create2(value, add(bytecode, 0x20), mload(bytecode), salt)
        }

        if (deployed == address(0)) revert DeploymentFailed();

        if (deployed != expectedAddress) {
            revert AddressMismatch(expectedAddress, deployed);
        }

        saltToContract[salt] = deployed;
        deployedContracts[msg.sender][salt] = deployed;

        emit ContractDeployed(deployed, salt, bytecode, value);
        return deployed;
    }

    function deployWithValue(
        bytes32 salt,
        bytes memory bytecode,
        uint256 value,
        uint256 initialValue
    ) external payable returns (address deployed) {
        if (msg.value < value) revert();

        deployed = deploy(salt, bytecode, value);
        if (value > 0) {
            payable(deployed).transfer(value);
        }

        if (initialValue > 0) {
            SimpleContract(deployed).value();
        }
    }

    function getDeployedContract(address deployer, bytes32 salt)
        external
        view
        returns (address)
    {
        return deployedContracts[deployer][salt];
    }

    function isSaltUsed(bytes32 salt) external view returns (bool) {
        return saltToContract[salt] != address(0);
    }

    function getContractCount() external view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < 1000; i++) {
            bytes32 salt = bytes32(i);
            if (saltToContract[salt] != address(0)) {
                count++;
            } else if (i > 100) {
                break;
            }
        }
        return count;
    }

    function findAvailableSalt(
        bytes memory bytecode,
        uint256 startFrom
    ) external view returns (bytes32 salt, address predictedAddress) {
        for (uint256 i = startFrom; i < type(uint256).max; i++) {
            bytes32 candidateSalt = bytes32(i);
            if (saltToContract[candidateSalt] == address(0)) {
                salt = candidateSalt;
                predictedAddress = getDeploymentAddress(
                    address(this),
                    candidateSalt,
                    bytecode
                );
                break;
            }
        }
    }
}