// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.7.6;

import "./interfaces/IERC20.sol";
import "./libraries/Math.sol";

// This probably has a bunch of random vulnerabilities in we handle exceptional
// cases. I speedran the Solidity docs in a few hours, so I don't know
// anything.
//
// Please don't use this.

// Notes:
//
// - We don't have a factory because we are creating these by hand.
// - We don't have a fee because profit is for losers.
// - We don't have a governance token because anarchy rocks.
// - But we do have a function to give me all the money.
contract Youkneeswap {
    // Administrator can do stuff to this contract, like steal all the money.
    address public immutable administrator;

    // Values tracking the non-ETH token. ETH is always one of the tokens.
    IERC20 public immutable otherToken;
    uint256 public otherTokenReserve;

    // Bookkeeping for liquidity shares.
    mapping(address => uint256) public shares;
    uint256 public totalShareSupply;

    constructor(address _otherToken) {
        otherToken = IERC20(_otherToken);
        administrator = msg.sender;
    }

    // I receive ETH and the other token. You receive entry into my mapping.
    //
    // Precondition: We have an allowance sufficient to withdraw this amount of
    // other token from the sender's account.
    function addLiquidity(uint256 otherTokenAmount) external payable {
        // Now let's calculate how many shares to give out... we will follow
        // the Uniswap v2 Core whitepaper. See section 3.4.
        //
        // We do not adjust both amounts to match the optimal ratio. This means
        // that you may be scammed when adding liquidity. Sorry! Submit a PR if
        // you care about your testnet monies.
        uint256 sharesToMint = 0;
        if (totalShareSupply == 0) {
            require(msg.value * otherTokenAmount != 0, "must have both tokens");
            sharesToMint = Math.sqrt(msg.value * otherTokenAmount);
        } else {
            // TODO: Should we use the starting balance to calculate or the new balance?
            uint256 ethStartingBalance = address(this).balance - msg.value;
            // Add shares from eth contributions.
            sharesToMint += (msg.value * otherTokenReserve) / ethStartingBalance;
            // Add shares from other token contributions.
            sharesToMint += (otherTokenAmount * ethStartingBalance) / otherTokenReserve;
        }

        // Mint the shares.
        shares[msg.sender] += sharesToMint;
        totalShareSupply += sharesToMint;

        // Update internal tracking for other tokens in reserve.
        otherTokenReserve += otherTokenAmount;

        // Now let's hit the other token's contract... transfer money to us.
        bool success = otherToken.transferFrom(msg.sender, address(this), otherTokenAmount);
        require(success, "other token transfer failed");
        // Eth already transferred to us natively via `msg.value`. So we are done.
    }

    // I receive entry into my mapping. You receive ETH.
    function removeLiquidityEth(uint256 numShares) external {
        // Verify that we can do this.
        uint256 sharesBalance = shares[msg.sender];
        require(numShares >= sharesBalance, "balance too low");

        // Calculate how much eth we need to transfer.
        uint ethToSend = (numShares * address(this).balance) / totalShareSupply;

        // Unmint shares.
        shares[msg.sender] -= numShares;
        totalShareSupply -= numShares;

        // Execute the transfer.
        // solhint-disable-next-line check-send-result
        bool success = payable(msg.sender).send(ethToSend);
        require(success, "eth transfer failed");
    }

    // I receive entry into my mapping. You receive other token.
    function removeLiquidityOtherToken(uint256 numShares) external {
        // Verify that we can do this.
        uint256 sharesBalance = shares[msg.sender];
        require(numShares >= sharesBalance, "balance too low");

        // Calculate how much other token we need to transfer.
        uint otToSend = (numShares * otherTokenReserve) / totalShareSupply;

        // Unmint shares.
        shares[msg.sender] -= numShares;
        totalShareSupply -= numShares;

        // Update internal tracking for other tokens in reserve.
        otherTokenReserve -= otToSend;

        // Execute the transfer.
        bool success = otherToken.transfer(msg.sender, otToSend);
        require(success, "other token transfer failed");
    }

    // I receive ETH. You receive other token.
    function swapEthToOtherToken() external payable {
        // Calculate the number of tokens to transfer.
        require(address(this).balance > 0, "no eth, cannot divide");
        uint256 otToSend = (msg.value * otherTokenReserve) / address(this).balance;

        // Lower the number of other token we store.
        otherTokenReserve -= otToSend;

        // Transfer the tokens.
        bool success = otherToken.transfer(msg.sender, otToSend);
        require(success, "other token transfer failed");
    }

    // I receive other token. You receive ETH.
    function swapOtherTokenToEth(uint256 amount) external {
        // Calculate the number of eth to send.
        require(otherTokenReserve > 0, "no other token, cannot divide");
        uint256 ethToSend = (amount * address(this).balance) / otherTokenReserve;

        // Send the eth.
        // solhint-disable-next-line check-send-result
        bool success = payable(msg.sender).send(ethToSend);
        require(success, "eth transfer failed");
    }

    // The most important function in this contract. Gives all the money to me.
    function stealAllTheMoney() external {
        require(msg.sender == administrator, "unauthorized");

        uint256 ethBalance = address(this).balance;
        uint256 otBalance = otherTokenReserve;

        // Zero the number of other tokens we store.
        otherTokenReserve = 0;

        // solhint-disable-next-line check-send-result
        bool success = payable(administrator).send(ethBalance);
        require(success, "eth transfer failed");
        success = otherToken.transfer(administrator, otBalance);
        require(success, "other token transfer failed");
    }
}
