// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IInbox } from "@arbitrum/nitro-contracts/src/bridge/IInbox.sol";

import { ArbitrumExecutor } from "./Executor.sol";

// Patch IInbox to add in calculate fee function
interface IInboxPatched is IInbox {
  function calculateRetryableSubmissionFee(
    uint256 dataLength,
    uint256 baseFee
  ) external view returns (uint256);
}

/**
 * @title Sender
 * @author Railgun Contributors
 * @notice Sets tasks on Arbitrum sender to executable
 */
contract ArbitrumSender is Ownable {
  // solhint-disable-next-line var-name-mixedcase
  IInboxPatched public immutable ARBITRUM_INBOX; // Arbitrum Inbox

  address public executorL2; // Sender contract on L2

  event RetryableTicketCreated(uint256 id);

  /**
   * @notice Sets contract addresses
   * @param _admin - delegator contract
   * @param _executorL2 - sender contract on L1
   * @param _arbitrumInbox - arbitrum inbox address
   */
  constructor(address _admin, address _executorL2, IInboxPatched _arbitrumInbox) {
    Ownable.transferOwnership(msg.sender);
    ARBITRUM_INBOX = _arbitrumInbox;
    setExecutorL2(_executorL2);
    Ownable.transferOwnership(_admin);
  }

  /**
   * @notice Sends ready task instruction to arbitrum executor
   * @param _task - task ID to ready
   */
  function readyTask(uint256 _task) external onlyOwner {
    // Calculate data
    bytes memory data = abi.encodeWithSelector(ArbitrumExecutor.readyTask.selector, _task);

    // Get submission fee
    uint256 submissionFee = ARBITRUM_INBOX.calculateRetryableSubmissionFee(
      data.length,
      block.basefee
    );

    // Create retryable ticket on arbitrum to set execution for governance task to true
    uint256 ticketID = ARBITRUM_INBOX.createRetryableTicket{ value: submissionFee }(
      executorL2,
      0,
      submissionFee,
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      0,
      0,
      data
    );

    // Emit event with ticket ID so EOAs can retry on Arbitrum if need be
    emit RetryableTicketCreated(ticketID);
  }

  /**
   * @notice Sets L2 executor address
   * @param _executorL2 - new executor address
   */
  function setExecutorL2(address _executorL2) public onlyOwner {
    executorL2 = _executorL2;
  }

  // Allow receiving ETH
  receive() payable external {}
}
