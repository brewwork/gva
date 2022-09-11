// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721r.sol";

contract Hawks is ERC721r {
    // 1601 is the number of tokens in the colletion
    uint256 TOTAL_SUPPLY = 1600;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmVbDfDcEWP7oLjd28cLEXJ8iATT4C6MuyVqwPs6QXhJSN";

    constructor() ERC721r("HHC Hawks", "HAWK", TOTAL_SUPPLY) {}
    
    function mint (uint quantity) external payable {
        _mintRandom(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}