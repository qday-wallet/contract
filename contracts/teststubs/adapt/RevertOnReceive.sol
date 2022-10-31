// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

contract RevertOnReceive {
  receive() external payable {
    revert();
  }
}
