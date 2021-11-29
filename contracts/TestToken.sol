// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.7.6;

import "./interfaces/IERC20.sol";

// A shitcoin for testing the AMM.
contract TestToken is IERC20 {
  mapping(address => uint256) public balances;

  // Everyon is allowed to mint new tokens.
  function mint(address _to, uint _amount) external {
    balances[_to] += _amount;
  }

  function balanceOf(address _owner) external override view returns (uint) {
    return balances[_owner];
  }

  // Everyone is allowed to spend everyone's coins.
  function allowance(
    address _owner,
    // solhint-disable-next-line no-unused-vars
    address _spender
  ) external override view returns (uint) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) external override returns (bool) {
    if (_value > balances[msg.sender]) {
      return false;
    }

    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  // Everyone is allowed to transfer everyone's coins.
  function transferFrom(
    address _from,
    address _to,
    uint _value
  ) external override returns (bool) {
    if (_value > balances[_from]) {
      return false;
    }

    balances[_from] -= _value;
    balances[_to] += _value;
    return true;
  }
}
