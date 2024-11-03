// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Interface.sol";

contract DutchAuction is IDutchAuction {
    address public seller;
    address timer;
    uint256 initialPrice;

    uint256 blockDecrement;
    uint256 duration;
    uint256 highestPrice;
    uint256 startAt;
    uint256 expireAt;
    bool public auctionEnded;
    bool public finalized;


    address public winner;
    // function winner() public view returns (address) {}

    uint256 public finalPrice;
    // function finalPrice() public view returns (uint256) {}

    // Note: Contract creator should be the seller
    constructor(
        uint256 _initialPrice,
        uint256 _blockDecrement,
        uint256 _duration
    ) {
        seller = msg.sender;
        initialPrice = _initialPrice;
        blockDecrement = _blockDecrement;
        duration = _duration;
        auctionEnded = false;
        startAt = block.number;
        expireAt = startAt + _duration;
        finalized = false;
        finalPrice = 0;
    }

    function bid() external payable override {

        require(!auctionEnded, "Bid: Auction already ended.");
        require(!finalized, "Auction has finalized");
        require(block.number < expireAt, "Block number exceeds duration.");
        uint256 currPrice = currentPrice();
        require(currPrice > 0, "Bid: Auction has ended, no bids allowed at zero price.");
        require(msg.value >= currPrice, "Bid is lower than the current price.");
        
        auctionEnded = true;
        winner = msg.sender;
        finalPrice = currPrice;
        highestPrice = msg.value;

        payable(msg.sender).transfer(highestPrice - finalPrice);

    }

    // Anyone can finalize the auction after the auction has ended
    function finalize() external override {
        require(block.number >= expireAt || auctionEnded || currentPrice() == 0, "Finalize: Auction not yet ended.");
        require(!finalized, "Finalize: Auction already finalized.");

        // Check if there was no bid placed
        if (winner == address(0)) {
            // No bids were placed, just mark as finalized, no Ether to transfer
            finalized = true;
            return;  // Exit the function
        }
        payable(seller).transfer(finalPrice);
        finalized = true;
    }

    function currentPrice() public view override returns (uint256) {
        uint256 blocksPassed = block.number - startAt;
        uint256 priceDecrement = blocksPassed * blockDecrement;
        if(priceDecrement >= initialPrice)
            return 0;
        else
            return initialPrice - priceDecrement;
    }
}
