// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.9;

/// @dev an interface to interact with the Genesis Verse NFT that will 
interface INFTStaking {
    function stake(uint256 tokenId, uint256 tokenHashPower) external;
    function stakeBatch(uint256[] memory tokenIds, uint256[] memory tokenHashPowers) external;
    function unstake(uint256 _tokenId) external;
    function unstakeBatch(uint256[] memory tokenIds) external;
    function claimReward() external;
    function unclaimedRewards(address _user) external view returns(uint256);
}