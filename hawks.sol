// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hawks is ERC721A, Ownable {
    uint256 MAX_MINTS = 10;  // not specified in white paper. Can be removed
    uint256 MAX_SUPPLY = 1600;

    //DUTCH Auction Variables
    uint256 public immutable startPrice = 1.5 ether;
    uint256 public immutable startAt;
    uint256 public immutable endsAt;
    uint256 public immutable endPrice = 0.1 ether;
    uint256 public immutable discountRate = 0.2 ether;
    uint256 public duration = 35 minutes;  // Looks like too early @Geremy, may be we need to configure it

    uint64 ownerIndex;

    struct AuctionData {
        address addr;   //Address of the owner
        uint64  quantity; //Number of NFT bought
        uint64  price;  //Mint Price
    }
    mapping(uint256 => AuctionData) private _auctionData;

    string public baseURI = "ipfs://bafybeieyetlp2c2vubffzjjap7utuz5jwo2k5b5kupvezfchc5tnfg4fh4/"; // Need to implement

    constructor() ERC721A("huge-hawk-club", "HAWK") {
        startAt = block.timestamp;
        endsAt = block.timestamp + duration;
        ownerIndex = 0;
    }

    function price() public view returns (uint256) {
        if (endsAt < block.timestamp) {
            return endPrice;
        }
        uint256 minutesElapsed = (block.timestamp - startAt) / 300;  // Price reduce in every 5 min
        return startPrice - (minutesElapsed * discountRate);
    }

    function setAuctionOwnerData (address _addr, uint64 _price, uint64 _quantity) internal {
        _auctionData[ownerIndex].addr = _addr;
        _auctionData[ownerIndex].price = _price;
        _auctionData[ownerIndex].quantity = _quantity;
        ownerIndex++;
    }

    function mint(uint64 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.

        require(msg.value >= (quantity * price()), "Not enough ether sent");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit"); //no limit as per current white paper
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        setAuctionOwnerData (msg.sender, uint64(msg.value), quantity);

        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // function TransferRefund external payable onlyOwner ()  // Yet to be implemented
}