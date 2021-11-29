// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.7.6;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint);
    function allowance(address _owner, address _spender) external view returns (uint);
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
}
