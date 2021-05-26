// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Token Whitelist
 * @author Railgun Contributors
 * @notice Whitelist of tokens allowed to be deposited in Railgun
 * @dev Tokens on this whitelist can be deposited to railgun.
 * Tokens can be removed from this whitelist but will still be transferrable
 * internally (as internal transactions have a shielded token ID) and
 * withdrawable (to prevent user funds from being locked)
 */

contract TokenWhitelist is Initializable, OwnableUpgradeable {
  // Events for offchain building of whitelist index
  event AddToTokenWhitelist(address indexed token);
  event RemoveFromTokenUnwhitelist(address indexed token);

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading
  mapping(address => bool) public tokenWhitelist;

  /**
   * @notice Adds initial set of tokens to whitelist.
   * @dev OpenZeppelin initializer ensures this can only be called once
   * @param _tokens - List of tokens to add to whitelist
   */

  function initializeTokenWhitelist(address[] calldata _tokens) internal initializer {
    // Push initial token whitelist to map
    addToWhitelist(_tokens);
  }

  /**
   * @notice Adds tokens to whitelist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that are already in the whitelist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to add to whitelist
   * @return success
   */

  function addToWhitelist(address[] calldata _tokens) public onlyOwner returns (bool success) {
    // Loop through token array
    for (uint i = 0; i < _tokens.length; i++) {
      // Get token
      address token = _tokens[i];

      // Don't do anything if the token is already whitelisted
      if (!tokenWhitelist[token]) {
          // Set token address in whitelist map to true
        tokenWhitelist[token] = true;

        // Emit event for building index of whitelisted tokens offchain
        emit AddToTokenWhitelist(token);
      }
    }

    return true;
  }

  /**
   * @notice Removes token from whitelist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that aren't in the whitelist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to remove from whitelist
   * @return success
   */

  function removeFromWhitelist(address[] calldata _tokens) external onlyOwner returns (bool success) {
    // Loop through token array
    for (uint i = 0; i < _tokens.length; i++) {
      // Get token
      address token = _tokens[i];

      // Don't do anything if the token isn't whitelisted
      if (tokenWhitelist[token]) {
        // Set token address in whitelist map to false (default value)
        delete tokenWhitelist[token];

        // Emit event for building index of whitelisted tokens offchain
        emit RemoveFromTokenUnwhitelist(token);
      }
    }

    return true;
  }

  uint256[50] private __gap;
}
