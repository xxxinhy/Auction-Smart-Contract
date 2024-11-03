// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Interface.sol";

contract VickreyAuction is IVickreyAuction {
    uint256 public reservePrice;
    uint256 public bidDeposit;
    address public seller;
    bool public finalized;
    uint256 bidStartAt;
    uint256 revealStartAt;
    uint256 revealEndAt;

    address public winner;
    // function winner() public view returns (address) {}
    uint256 public finalPrice;
    // function finalPrice() public view returns (uint256) {}

    address public highestBidder;
    // function highestBidder() public view returns (address) {}
    uint256 public secondHighestBid;
    uint256 public HighestBid;
    // function secondHighestBid() public view returns (uint256) {}

    // Note: Contract creator should be the seller
    constructor(
        uint256 _reservePrice,
        uint256 _bidDeposit,
        uint256 _biddingPeriod,
        uint256 _revealPeriod
    ) {
        seller = msg.sender;
        reservePrice = _reservePrice;
        bidStartAt = block.number;
        revealStartAt = bidStartAt+ _biddingPeriod;
        revealEndAt = revealStartAt + _revealPeriod;
        bidDeposit = _bidDeposit;
        HighestBid = 0;
        secondHighestBid = 0;
        finalized = false;

    }
    // Add a mapping to track if a bidder has commited their bid
    mapping(address => bool) private hasCommited;
    // Add a mapping to track if a bidder has revealed their bid
    mapping(address => bool) private hasRevealed;
    // Can use mapping to store the commitment for each bidder
    mapping(address => bytes32) private bidCommitments;

    // Record the player's bid commitment
    // Make sure at least bidDepositAmount is provided (for new bids)
    // Bidders can update their previous bid for free if desired.
    // Only allow commitments before biddingDeadline
    function commitBid(bytes32 bidCommitment) external payable override {
        require((revealStartAt > block.number),"Bidding period has ended");
        if(hasCommited[msg.sender]==true){
            bidCommitments[msg.sender] = bidCommitment;
            payable(msg.sender).transfer(msg.value);
        }else{
            require(msg.value >= bidDeposit, "bidDeposit below least Amount");
        }
        if (msg.value > bidDeposit) {
            payable(msg.sender).transfer(msg.value - bidDeposit); // Refund the extra amount
        }
        hasCommited[msg.sender]=true;
        bidCommitments[msg.sender] = bidCommitment;
    }

    // Check that the bid (msg.value) matches the commitment
    // If the bid is below the minimum price, it is ignored but the deposit is returned.
    // If the bid is below the current highest known bid, the bid value and deposit are returned.
    // If the bid is the new highest known bid, the deposit is returned and the previous high bidder's bid is returned.
    function revealBid(bytes32 nonce) external payable override {
        require(bidCommitments[msg.sender] == makeCommitment(msg.value,nonce),"commit doesn't match");
        require((revealStartAt <= block.number && block.number < revealEndAt),"Not in Reveal period");
        require(!hasRevealed[msg.sender], "Bid has already been revealed");
        hasRevealed[msg.sender] = true;


        if (msg.value < reservePrice) {
            payable(msg.sender).transfer(bidDeposit+msg.value);
            return;
        }
        
        if(msg.value>HighestBid){
            if(highestBidder != address(0)){
                payable(highestBidder).transfer(HighestBid);
            }
            secondHighestBid = HighestBid;
            HighestBid = msg.value;
            highestBidder = msg.sender;

        }else if(msg.value> secondHighestBid){
            secondHighestBid = msg.value;
            payable(msg.sender).transfer(msg.value);
        }else{
            payable(msg.sender).transfer(msg.value);
        }
        payable(msg.sender).transfer(bidDeposit);
    }

    // This function shows how to make a commitment
    function makeCommitment(
        uint256 bidValue,
        bytes32 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bidValue, nonce));
    }

    // Anyone can finalize the auction after the reveal period has ended
    function finalize() external override {
        require((revealEndAt <= block.number),"Reveal period has not ended");
        require(!finalized,"Auction has finalized.");
        if (HighestBid == 0) {
            finalized = true;
            return;
        }
        if(secondHighestBid == 0) 
            secondHighestBid = reservePrice;

        winner = highestBidder;
        finalPrice = secondHighestBid;
        
        
        if(HighestBid>finalPrice)
            payable(winner).transfer(HighestBid - finalPrice);
        payable(seller).transfer(finalPrice);

        finalized = true;
    }
}
