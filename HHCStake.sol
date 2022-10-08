// SPDX-License-Identifier: HHC
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HHCStake is Ownable, ERC721Holder {

    struct StakeData {
        address      addr;            //Address of the owner
        uint256      tokenId;        //Staked NFT
        uint256      stakeStartTime;  //Stake start time
    }

    uint64 private totalStaked = 0;
    IERC721 public nft;
    mapping(uint256 => StakeData) private _StakeData;

    event Staked(address owner, uint256 _nftID);
    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 _nftID);

    event AlreadyStaked(uint256 _nftID, address owner);


    constructor (IERC721 _nft) {
        nft = _nft;
    }

    function stake (uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(
            nft.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );
        StakeData memory data;
        data.tokenId = _tokenId;
        data.addr = _user;
        data.stakeStartTime = block.timestamp;

        nft.approve(address(this), _tokenId);
        nft.safeTransferFrom(_user, address(this), _tokenId);
        _StakeData[_tokenId] = data;

        emit Staked(_user, _tokenId);
        totalStaked++;
    }

    function unstake(uint256 _tokenId) public {
        _unstake(msg.sender, _tokenId);
    }


    function _unstake(address _user, uint256 _tokenId) internal {
        StakeData memory data = _StakeData[_tokenId];
        require(
            data.addr == _user,
            "Nft Staking System: user must be the owner of the staked nft"
        );

        delete _StakeData[_tokenId];

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        totalStaked--;
    }

    function getTotalNumberOfStakedItem () view public returns (uint256){
        return totalStaked;
    }

    function isNftStaked (uint256 _tokenId) public{
        StakeData memory data = _StakeData[_tokenId];
        emit AlreadyStaked(_tokenId, data.addr);
    }
}