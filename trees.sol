// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Trees is ERC721A, Ownable {
    uint256 MAX_MINTS = 10;  // no requirement in white paper, can be removed
    uint256 MAX_SUPPLY = 2701;

    IERC20 public tokenAddress;
    uint256 public rate = 100 * 10 ** 18;

    string public baseURI = "ipfs://bafybeieyetlp2c2vubffzjjap7utuz5jwo2k5b5kupvezfchc5tnfg4fh4/"; //TO-DO

    constructor(address _tokenAddress) ERC721A("huge-hawk-club", "TREE") {
        tokenAddress = IERC20(_tokenAddress);
    }

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        tokenAddress.transferFrom(msg.sender, address(this), rate*quantity);

        _safeMint(msg.sender, quantity);
    }

    function withdrawToken() public onlyOwner {
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}