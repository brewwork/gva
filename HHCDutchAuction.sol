// SPDX-License-Identifier: HHC
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "ERC721r.sol";


contract HHCDutchAuction is Ownable, ERC721r  {

    uint64 constant MAX_SUPPLY = 10000; // 10K (8400 sloth + 1600 Hawk)
    uint maxMint = 10;

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionStarted,
        AuctionEnded,
        AuctionClaimDone
    }

    struct AuctionData {
        address addr;   //Address of the owner
        uint64  quantity; //Number of NFT bought
        uint64  price;  //Mint Price
    }

    //DUTCH Auction Variables
    uint256 internal startPrice = 1.5 * 10**18 wei;
    uint256 public  startAt;
    uint256 public  endsAt;
    uint256 internal  endPrice = 0.1 * 10**18 wei;
    uint256 public  discountRate = 0.2 * 10**18 wei;
    uint256 public  minDuration = 35 minutes;
    uint64 internal currAvailableItems = MAX_SUPPLY;
    uint256 internal  finalPrice;
    uint256 internal  lastAuctionPrice = startPrice;
    //address internal wallet;
    
    Stages internal stage = Stages.AuctionDeployed;
    uint64 ownerIndex;
    mapping(uint256 => AuctionData) private _auctionData;

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        require (_stage == stage, "Stage do not match");
        _;
    }

    function startAuction(uint64 _startPrice, uint256 auctionDurationInSeconds) external 
    //onlyOwner //Comment only owner for testing
    atStage(Stages.AuctionDeployed)
    {
        startPrice = _startPrice;

        startAt = block.timestamp;
        require(auctionDurationInSeconds >= minDuration, "Minimum Auction duration shall be 35 Minutes");
        endsAt = block.timestamp + auctionDurationInSeconds;
        //wallet = address(this);
        stage = Stages.AuctionStarted;
    }

    function CalculateCurrentPrice() public atStage(Stages.AuctionStarted) returns (uint256) {
        if (endsAt < block.timestamp) {
            return endPrice;
        }
        uint256 minutesElapsed = (block.timestamp - startAt) / 300;  // Price reduce in every 5 min
        lastAuctionPrice = startPrice - (minutesElapsed * discountRate);
        return lastAuctionPrice;
    }

    function getLastAuctionPrice () view public
    atStage(Stages.AuctionStarted) returns (uint256){
        return lastAuctionPrice;
    }

    function getStartAuctionPrice () view public
    atStage(Stages.AuctionStarted) returns (uint256){
        return startPrice;
    }

    function getMaxMintNumber () view public
    atStage(Stages.AuctionStarted) returns (uint256){
        return maxMint;
    }

    function getTotalItems () view public
    atStage(Stages.AuctionStarted) returns (uint256){
        return MAX_SUPPLY;
    }

    function getAvailableNumberOfItems () view public 
    atStage(Stages.AuctionStarted) returns (uint64){
        return currAvailableItems;
    }

    function endAuction() payable 
    public //onlyOwner
    atStage(Stages.AuctionStarted)
    {
        finalPrice = CalculateCurrentPrice();
        stage = Stages.AuctionEnded;
    }

    function setAuctionOwnerData (address _addr, uint64 _price, uint64 _quantity) internal {
        _auctionData[ownerIndex].addr = _addr;
        _auctionData[ownerIndex].price = _price;
        _auctionData[ownerIndex].quantity = _quantity;
        ownerIndex++;
    }


    function getPlayerIndex (address sender) internal returns (uint64) {
        for (uint64 i = 0; i < ownerIndex ; i++)
        {
            if (_auctionData[i].addr == sender)
            {
                return i;
            }
        }
        return (MAX_SUPPLY*2);
    }

    function numberOfAllocations (address sender) internal returns (uint64){
        uint64 index = getPlayerIndex (sender);
        if (index < MAX_SUPPLY)
        {
            return _auctionData[index].quantity;
        }
        return 0;
    }

    function bid(uint64 quantity) public payable
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        uint64 previousAllocation = 0;
        previousAllocation = numberOfAllocations(msg.sender);
        amount = msg.value;
        require(quantity + previousAllocation <= maxMint, "User Exceeded the mint limit");
        require(quantity <= currAvailableItems, "Not enough tokens left");
        require(msg.value >= (quantity * CalculateCurrentPrice()), "Not enough ether sent");
        payable(owner()).transfer(msg.value);

        setAuctionOwnerData (msg.sender, uint64(msg.value), quantity);
        currAvailableItems = currAvailableItems - quantity;

        if (currAvailableItems <= 0)
        {
            endAuction();
        }
    }

    function withdraw() external payable onlyOwner
    atStage(Stages.AuctionEnded) {
        uint256 totalWithdrawable = 0;
        totalWithdrawable = (MAX_SUPPLY - currAvailableItems) * finalPrice;
        payable(owner()).transfer(totalWithdrawable);
    }

    function claimExtraAmount () external payable
    atStage(Stages.AuctionEnded) {
        uint64 idx = 0;
        idx = getPlayerIndex (msg.sender);
        require (idx < MAX_SUPPLY, "USER not found");
        uint256 balance = _auctionData[idx].price - (_auctionData[idx].quantity * finalPrice);
        require(balance > 0, "No balance amount to Claim");
        payable(msg.sender).transfer (balance);
    }

    

/****************** ERC721 NFT data ***********************************************/
    string public baseURI = 
    "https://gateway.pinata.cloud/ipfs/QmVbDfDcEWP7oLjd28cLEXJ8iATT4C6MuyVqwPs6QXhJSN";
    event  NFTMinted (address _to, uint256 _id);
    constructor() ERC721r("HHC NFT", "HHC", MAX_SUPPLY) {}
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function claimToken () external payable
    atStage(Stages.AuctionEnded) {
        uint64 previousAllocation = 0;
        previousAllocation = numberOfAllocations(msg.sender);
        require (previousAllocation > 0, "USER not found");

        _mintRandom(msg.sender, previousAllocation);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        emit NFTMinted (to, tokenId);
        super._afterTokenTransfer(from, to, tokenId);
    }
}