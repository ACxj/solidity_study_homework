// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract OpenAceToken is ERC20, Ownable, Pausable {
    uint8 private _decimals;
    uint256 private constant MAX_BATCH_SIZE = 50;

    error ArrayLengthMismatch();
    error BatchSizeExceeded();

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        uint8 decimals_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply * 10 ** decimals_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external whenNotPaused {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    function transfer(address to, uint256 amount) public whenNotPaused override returns (bool) {
        return super.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) public whenNotPaused override returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused override returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function batchTransfer(address[] memory recipients, uint256[] memory amounts) external whenNotPaused returns (bool) {
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();
        if (recipients.length == 0) revert ArrayLengthMismatch();
        if (recipients.length > MAX_BATCH_SIZE) revert BatchSizeExceeded();

        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }

        if (balanceOf(msg.sender) < totalAmount) revert ERC20InsufficientBalance(msg.sender, balanceOf(msg.sender), totalAmount);

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }

        return true;
    }
}