// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.4;

import "./interfaces/IERC20.sol";
import "./libraries/Math.sol";

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
    uint256 public totalShareSupply;

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
        // TODO: Is this a reentrancy vulnerability? I guess we trust that
        // allowance in that contract is correctly written, so probably not?
        uint256 otherTokenAllowance = otherToken.allowance(msg.sender, address(this));
        require(otherTokenAmount > otherTokenAllowance, "insufficient other token allowance");

        // Now let's calculate how many shares to give out... we will follow
        // the Uniswap v2 Core whitepaper. See section 3.4.
        //
        // We do not adjust both amounts to match the optimal ratio. This means
        // that you may be scammed when adding liquidity. Sorry! Submit a PR if
        // you care about your testnet monies.
        uint256 sharesToMint = 0;
        if (totalShareSupply == 0) {
            require(msg.value * otherTokenAmount != 0, "initial min must have both tokens");
            sharesToMint = Math.sqrt(msg.value * otherTokenAmount);
        } else {
            uint256 ethStartingBalance = address(this).balance - msg.value;
            // Add shares from eth contributions.
            sharesToMint += (msg.value * otherTokenReserve) / ethStartingBalance;
            // Add shares from other token contributions.
            sharesToMint += (otherTokenAmount * ethStartingBalance) / otherTokenReserve;
        }

        // Mint the shares.
        shares[msg.sender] += sharesToMint;
        totalShareSupply += sharesToMint;

        // Now let's hit the other token's contract... transfer money to us.
        bool success = otherToken.transferFrom(msg.sender, address(this), otherTokenAmount);
        require(success, "other token transfer failed");
        // Eth already transferred to us natively via `msg.value`. So we are done.
    }

    // I receive entry into my mapping. You receive ETH.
    function removeLiquidityEth(
        uint256 numShares
    ) external {
        // Verify that we can do this.
        uint256 sharesBalance = shares[msg.sender];
        require(numShares >= sharesBalance, "balance too low");

        // Calculate how much eth we need to transfer.
        uint ethToSend = (numShares * address(this).balance) / totalShareSupply;

        // Execute the transfers.
        shares[msg.sender] -= numShares;
        bool success = payable(msg.sender).send(ethToSend);
        require(success, "eth transfer failed");
    }

    // I receive entry into my mapping. You receive other token.
    function removeLiquidityOtherToken(
        uint256 numShares
    ) external {
        // Verify that we can do this.
        uint256 sharesBalance = shares[msg.sender];
        require(numShares >= sharesBalance, "balance too low");

        // Calculate how much other token we need to transfer.
        uint otToSend = (numShares * otherTokenReserve) / totalShareSupply;

        // Execute the transfers.
        shares[msg.sender] -= numShares;
        bool success = otherToken.transfer(msg.sender, otToSend);
        require(success, "other token transfer failed");
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
