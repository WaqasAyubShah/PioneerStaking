// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.9;

import "../interfaces/IRewardsController.sol";

contract HashPowerRewardsController is IRewardsController {

    uint public rewardPerBlock = 100;
    uint public lastUpdateBlock;
    
    uint public rewardPerHashStored;

    mapping(address => uint) public userRewardPerHashPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor() {
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerHashStored +
            (((block.number - lastUpdateBlock) * rewardPerBlock * 1e18) / _totalSupply);
    }

    function unclaimedRewards(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerHashPaid[account])) / 1e18) +
            rewards[account];
    }

    function stake(address account, uint _amount) external {
        updateReward(account);

        _totalSupply += _amount;
        _balances[account] += _amount;
    }

    function unstake(address account, uint _amount) external {
        updateReward(account);

        _totalSupply -= _amount;
        _balances[account] -= _amount;
    }

    function harvest(address account) external returns (uint) {
        updateReward(account);

        uint reward = rewards[account];
        rewards[account] = 0;

        return reward;
    }

    function updateReward(address account) private {
        rewardPerHashStored = rewardPerToken();
        lastUpdateBlock = block.number;

        rewards[account] = unclaimedRewards(account);
        userRewardPerHashPaid[account] = rewardPerHashStored;
    }
}