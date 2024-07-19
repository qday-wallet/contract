// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import "../adapt/IWBase.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract WQday is ERC20, IWBase {
  /// @notice The amount of QDay to deposit.
  /// @param amount The amount of QDay to deposit.
  event Deposit(address indexed dst, uint amount);

  /// @notice The amount of QDay to withdraw.
  /// @param amount The amount of QDay to withdraw.
  event Withdrawal(address indexed src, uint amount);

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  receive() external payable {}

  /// @notice The amount of QDay to deposit.
  function deposit() external payable {
    _mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  /// @notice The amount of QDay to withdraw.
  /// @param amount The amount of QDay to withdraw.
  function withdraw(uint256 amount) external {
    require(balanceOf(msg.sender) >= amount);
    _burn(msg.sender, amount);
    payable(msg.sender).transfer(amount);
    emit Withdrawal(msg.sender, amount);
  }
}
