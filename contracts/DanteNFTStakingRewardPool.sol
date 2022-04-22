// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DanteNFTStakingRewardPool is Ownable {
    IERC721 public parentNFT;

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
    }

    // map staker address to stake details
    mapping(address => Stake) public stakes;

    // map staker to total staking time 
    mapping(address => uint256) public stakingTime;    

    constructor(address nft) {
        parentNFT = IERC721(nft);
    }

    function stake(uint256 _tokenId) public {
        stakes[msg.sender] = Stake(_tokenId, block.timestamp); 
        parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId, "0x00");
    } 

    function unstake() public {
        parentNFT.safeTransferFrom(address(this), msg.sender, stakes[msg.sender].tokenId, "0x00");
        stakingTime[msg.sender] += (block.timestamp - stakes[msg.sender].timestamp);
        delete stakes[msg.sender];
    }      

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function distributeRewards() onlyOwner external {
        
    }

}