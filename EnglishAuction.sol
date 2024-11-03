// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Assignment2.sol";

contract EnglishAuction is IEnglishAuction {
    uint256 public minIncrement;
    address public seller;

    address public winner;
    uint256 public finalPrice;
    uint256 public biddingPeriod;
    uint256 initialPrice;
    uint256 startAt;
    bool finalized;

    address public highestBidder;
    // function highestBidder() public view returns (address) {}
    uint256 public highestBid;
    // function highestBid() public view returns (uint256) {}

    // Note: Contract creator should be the seller
    constructor(
        uint256 _initialPrice,
        uint256 _minIncrement,
        uint256 _biddingPeriod
    ) {
        minIncrement = _minIncrement;
        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        seller = msg.sender;
        finalized = false;
        startAt= block.number;
    }

    function bid() external payable override {
        require(msg.value >= initialPrice, "Bid must be at least the initial price.");
        require(msg.value >= highestBid + minIncrement, "Bid must be higher than minIncrement");
        require((startAt + biddingPeriod) > block.number, "Bid exceeds bidding period");
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }
        startAt = block.number;
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    // Anyone can finalize the auction after the bidding period has ended
    function finalize() external override {
        require(!finalized, "Auction has finalized");
        require((startAt + biddingPeriod) <= block.number, "bidding has not over");
        winner = highestBidder;
        finalPrice = highestBid;
        payable(seller).transfer(highestBid);
        finalized = true;
    }
}
