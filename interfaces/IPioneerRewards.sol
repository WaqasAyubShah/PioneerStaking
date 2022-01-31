// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.9;

/// @dev an interface to interact with the Genesis Verse NFT that will 
interface IPioneerRewards {
    function updateRewards() external returns (bool);
    function genesisRewards(uint256 _from, uint256 _to) external view returns(uint256);
    function parentRewards(uint256 _from, uint256 _to) external view returns(uint256);
    function lastRewardTime() external view returns (uint256);
}
