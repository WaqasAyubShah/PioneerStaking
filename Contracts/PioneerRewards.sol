// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./PioneerAccessControls.sol";
import "../interfaces/IERC20.sol";



/**
 * @title Pioneer Rewards
 * @dev Calculates the rewards for staking on the Pioneer platform
 */

interface PioneerStaking {
    function stakedEthTotal() external view returns (uint256);
    function lpToken() external view returns (address);
    function WETH() external view returns (address);
}

interface Verse is IERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool);
}

contract PioneerRewards {
    using SafeMath for uint256;

    /* ========== Variables ========== */

    Verse public rewardsToken;
    PioneerAccessControls public accessControls;
    PioneerStaking public genesisStaking;
    PioneerStaking public parentStaking;
    

    uint256 constant pointMultiplier = 10e18;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_WEEK = 7 * 24 * 60 * 60;
    
    // weekNumber => rewards
    mapping (uint256 => uint256) public weeklyRewardsPerSecond;
    mapping (address => mapping(uint256 => uint256)) public weeklyBonusPerSecond;

    uint256 public startTime;
    uint256 public lastRewardTime;

    uint256 public genesisRewardsPaid;
    uint256 public parentRewardsPaid;
   

    /* ========== Structs ========== */

    struct Weights {
        uint256 genesisWtPoints;
        uint256 parentWtPoints;
        uint256 lpWeightPoints;
    }

    /// @notice mapping of a staker to its current properties
    mapping (uint256 => Weights) public weeklyWeightPoints;

    /* ========== Events ========== */

    event RewardAdded(address indexed addr, uint256 reward);
    event RewardDistributed(address indexed addr, uint256 reward);
    event Recovered(address indexed token, uint256 amount);

    
    /* ========== Admin Functions ========== */
    constructor(
        Verse _rewardsToken,
        PioneerAccessControls _accessControls,

    )
        public
    {
        rewardsToken = _rewardsToken;
        accessControls = _accessControls;
            
    }
}