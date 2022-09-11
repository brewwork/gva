// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721r.sol";

contract Hawks is ERC721r {
    // 1600 is the number of tokens in the colletion
    uint256 MAX_SUPPLY = 1600;
    uint256 MAX_MINTS = 10;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmVbDfDcEWP7oLjd28cLEXJ8iATT4C6MuyVqwPs6QXhJSN";

    constructor() ERC721r("HHC Hawks", "HAWK", MAX_SUPPLY) {}
    
    function mint (uint quantity) external payable {
        require(quantity <= MAX_MINTS, "Not allowed to mint more than limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _mintRandom(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}