// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.9;

/// @dev an interface to interact with the Genesis Verse NFT that will 
interface IRewardsController {
    function stake(address account, uint _amount) external;
    function unstake(address account, uint _amount) external;
    function unclaimedRewards(address account) external view returns (uint);
    function harvest(address account) external returns (uint);
}
