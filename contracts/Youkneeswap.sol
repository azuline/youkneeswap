// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.4;

import "./interfaces/IERC20.sol";

// This probably has a bunch of random vulnerabilities in we handle exceptional
// cases. I speedran the Solidity docs in a few hours, so I don't know anything
// intimately.
//
// Please don't use this.

// Notes:
//
// - We don't have a factory because we are creating these by hand.
// - We don't have a fee because profit is for lowers.
// - We don't have a governance token because anarchy is best.
// - We don't have an approval system.
// - We trade gas for clarity.
// - But we do have a function to give me all the money.
contract YoukneeswapVFinalDocx {
    // Administrator can do stuff to this contract, like steal all the money.
    address public immutable administrator;

    // Values tracking the non-ETH token. ETH is always one of the tokens.
    IERC20 public immutable otherToken;
    uint256 private otherTokenReserve; // Defaults to 0.

    // Bookkeeping for liquidity shares.
    mapping(address => uint256) public shares;
    uint256 public numShares;

    constructor(address _otherToken) {
        otherToken = IERC20(_otherToken);
        administrator = msg.sender;
    }

    // I receive ETH and the other token. You receive entry into my mapping.
    function addLiquidity(
        uint256 otherTokenAmount
    ) external payable {
        // First let's make sure we can steal that number of tokens from the
        // sender.
        uint256 otherTokenAllowance = otherToken.allowance(msg.sender, address(this));
        require(otherTokenAmount > otherTokenAllowance, "insufficient other token allowance");

        // Now let's calculate how many shares to give out... we will follow
        // the Uniswap v2 Core whitepaper. See section 3.4.
        //
        // I think Uniswap chooses to add liquidity such that both currencies
        // result in the same number of shares to be allocated. This simplifies
        // the security model. But I'm a lazy shit so I will allocate shares
        // for each currency, despite the likely risk that this introduces an
        // exploit.
        uint256 sharesToMint = 0;
        if (numShares == 0) {
            // TODO: sqrt(msg.value * otherTokenAmount);
            // I think I need to switch to a different number library; might steal ffffff
            sharesToMint = 0;
        } else {
            uint ethStartingBalance = address(this).balance - msg.value;
            // Add shares from eth contributions.
            sharesToMint += (msg.value * otherTokenReserve) / ethStartingBalance;
            // Add shares from other token contributions.
            sharesToMint += (otherTokenAmount * ethStartingBalance) / otherTokenReserve;
        }

        // Mint the shares.
        shares[msg.sender] += sharesToMint;
        numShares += sharesToMint;

        // Now let's hit the other token's contract... transfer money to us.
        otherToken.transferFrom(msg.sender, address(this), otherTokenAmount);
        // Eth already transferred to us natively via `msg.value`.
    }

    function removeLiquidity(
        uint256 liquidity
    ) external {
        // TODO
    }

    function swapEthToToken(
        uint256 amount
    ) external payable {
        // TODO
    }

    function swapTokenToEth(
        uint256 amount
    ) external {
        // TODO
    }

    // The most important function in this contract. Gives all the money to me.
    function stealAllTheMoney() external {
        require(msg.sender == administrator, "unauthorized");

        uint256 ethBalance = address(this).balance;
        uint256 otBalance = otherToken.balanceOf(address(this));

        bool success = payable(administrator).send(ethBalance);
        require(success, "eth transfer failed");
        success = otherToken.transfer(administrator, otBalance);
        require(success, "other token transfer failed");
    }
}
