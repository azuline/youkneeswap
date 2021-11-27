// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.4;

// This probably has a bunch of random vulnerabilities in we handle exceptional
// cases. I speedran the Solidity docs in a few hours, so I don't know anything
// intimately.
//
// Please don't use this.

// Notes:
//
// - We don't have a factory because we are creating these by hand.
// - We don't have a governance token because anarchy is best.
// - We don't have an approval system.
// - But we do have a function to give me all the money.
contract YoukneeswapVFinalDocx {
    // Administrator can do stuff to this contract, like steal all the money,
    // IDK.
    address public immutable administrator;

    // Values tracking the other non-ETH token. ETH is always one of the
    // tokens.
    address public immutable otherToken;
    // Defaults to 0.
    uint112 private otherTokenReserve;

    constructor(address _otherToken) {
        otherToken = _otherToken;
        administrator = msg.sender;
    }

    // The most important function in this contract. Gives all the money to me.
    function stealAllTheMoney() external {
        require(msg.sender == administrator, "unauthorized");

        uint256 ethBalance = address(this).balance;
        bool ethSuccess = payable(administrator).send(ethBalance);
        require(ethSuccess, "eth transfer failed");

        uint256 otherTokenBalance = IERC20(otherToken).balanceOf(address(this));
        bool otSuccess = transferOtherToken(
            address(this), // from
            administrator, // to
            otherTokenBalance
        );
        require(otSuccess, "other token transfer failed");
    }

    // Section: Internal utility functions.

    // Returns success of transfer.
    function transferOtherToken(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        // 0x23b872dd == bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        // Thanks Uniswap!
        (bool success, bytes memory data) =
            otherToken.call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}

// From https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol.
// I hope interfaces aren't copyright.
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
