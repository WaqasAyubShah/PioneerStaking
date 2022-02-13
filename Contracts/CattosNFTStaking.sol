// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./PioneerAccessControls.sol";
import "./PioneerGenesisNFT.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPioneerRewards.sol";
import "../interfaces/IPioneerNFT.sol";
import "../interfaces/IRewardsController.sol";
import "../interfaces/INFTStaking.sol";

/**
 * @title Welcome NFT Staking
 * @dev Stake NFTs, earn tokens on the Our platform
 * @author Syed Muhammad Waqas (wiki)
 */

contract CattosNFTStaking is INFTStaking {
    using SafeMath for uint256;
    bytes4 private constant _ERC721_RECEIVED = 1;

    IERC20 public rewardsToken;
    IPioneerNFT public nftToken;
    PioneerAccessControls public accessControls;

    // Rewards Controller
    IRewardsController public rewardsController;

    // Total hash power staked currently
    uint256 public stakedHashPowerTotal;

    /**
    @notice Struct to track what user is staking which tokens
    @dev tokenIds are all the tokens staked by the staker
    @dev balance is the current ether balance of the staker
    */
    struct Staker {
        uint256[] tokenIds;
        uint256 balance;

        mapping (uint256 => uint256) tokenToHashPower;
    }

    // Mapping of stakers to its current properties
    mapping (address => Staker) public stakers;

    // Mapping from token ID to owner address
    mapping (uint256 => address) public tokenOwner;

    /// @notice sets the token to be claimable or not, cannot claim if it set to false
    bool public tokensClaimable;
    bool initialised;

    /// @notice event emitted when a user has staked a token
    event Staked(address owner, uint256 amount);

    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address owner, uint256 amount);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);
    
    /// @notice Allows reward tokens to be claimed
    event ClaimableStatusUpdated(bool status);

    /// @notice Emergency unstake tokens without rewards
    event EmergencyUnstake(address indexed user, uint256 tokenId);

    /// @notice Admin update of rewards contract
    event RewardsTokenUpdated(address indexed oldRewardsToken, address newRewardsToken );

    constructor() public {
    }
     /**
     * @dev Single gateway to intialize the staking contract after deploying
     * @dev Sets the contract with the Cattos NFT and Cattos reward token 
     */
    function initStaking(
        IERC20 _rewardsToken,
        PioneerNFT _nftToken,
        PioneerControls _accessControls
    )
        external
    {
        require(!initialised, "Already initialised");
        rewardsToken = _rewardsToken;
        nftToken = _nftToken;
        accessControls = _accessControls;
        initialised = true;
    }


    /// @notice Lets admin set the Rewards Token
    function setRewardsController(
        address _addr
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "CattosNFTStaking.setRewardsController: Sender must be admin"
        );
        require(_addr != address(0));
        address oldAddr = address(rewardsController);
        rewardsController = IRewardsController(_addr);
        emit RewardsTokenUpdated(oldAddr, _addr);
    }

    /// @notice Lets admin set the Rewards to be claimable
    function setTokensClaimable(
        bool _enabled
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "PioneerParentStaking.setTokensClaimable: Sender must be admin"
        );
        tokensClaimable = _enabled;
        emit ClaimableStatusUpdated(_enabled);
    }

    /// @dev Getter functions for Staking contract
    /// @dev Get the tokens staked by a user
    function getStakedTokens(
        address _user
    )
        external
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }


    /// @dev Get the amount a staked nft is valued at ie bought at
    function getTokenHashPower (
        uint256 _tokenId
    ) 
        public
        view
        returns (uint256)
    {
        address owner = tokenOwner[_tokenId];
        return stakers[owner].tokenToHashPower[_tokenId];
    }

    /// @notice Stake Cattos NFTs and earn reward tokens. 
    function stake(
        uint256 tokenId,
        uint256 tokenHashPower
    )
        external
    {
        // require();
        _stake(msg.sender, tokenId, tokenHashPower);
    }

    /// @notice Stake multiple Cattos NFTs and earn reward tokens. 
    function stakeBatch(uint256[] memory tokenIds, uint256[] memory tokenHashPowers)
        external
    {
        for (uint i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], tokenHashPowers[i]);
        }
    }

    /**
     * @dev All the staking goes through this function
     * @dev Rewards to be given out is calculated
     * @dev Balance of stakers are updated as they stake the nfts based on ether price
    */
    function _stake(
        address _user,
        uint256 _tokenId,
        uint256 _tokenHashPower
    )
        internal
    {
        // Stake via Controller
        rewardsController.stake(_user, _tokenHashPower);

        // Update staker data
        Staker storage staker = stakers[_user];
        staker.balance = staker.balance.add(_tokenHashPower);
        stakedHashPowerTotal = stakedHashPowerTotal.add(_tokenHashPower);
        staker.tokenIds.push(_tokenId);
        staker.tokenToHashPower[_tokenId] = _tokenHashPower;

        tokenOwner[_tokenId] = _user;

        // Transfer NFT to this contract
        nftToken.safeTransferFrom(
            _user,
            address(this),
            _tokenId
        );

        emit Staked(_user, _tokenId);
    }

    /// @notice Unstake Genesis Cattos NFTs. 
    function unstake(
        uint256 _tokenId
    ) 
        external 
    {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "PioneerParentStaking._unstake: Sender must have staked tokenID"
        );

        _unstake(msg.sender, _tokenId);
    }

    /// @notice Stake multiple Cattos NFTs and claim reward tokens. 
    function unstakeBatch(
        uint256[] memory tokenIds
    )
        external
    {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }

     /**
     * @dev All the unstaking goes through this function
     * @dev Rewards to be given out is calculated
     * @dev Balance of stakers are updated as they unstake the nfts based on ether price
    */
    function _unstake(
        address _user,
        uint256 _tokenId
    ) 
        internal 
    {

        // Find token hash power
        uint256 tokenHashPower = getTokenHashPower(_tokenId);

        // Unstake via Controller
        rewardsController.unstake(_user, tokenHashPower);

        // Update staker data
        Staker storage staker = stakers[_user];
        staker.balance = staker.balance.sub(tokenHashPower);
        stakedHashPowerTotal = stakedHashPowerTotal.sub(tokenHashPower);
        
        // Remove staked token from staker.tokenIds
        _removeStakedToken(_user, _tokenId);

        delete staker.tokenToHashPower[_tokenId];

        if (staker.balance == 0) {
            delete stakers[_user];
        }

        delete tokenOwner[_tokenId];

        // Transfer NFT to original owner
        nftToken.safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );

        emit Unstaked(_user, _tokenId);

    }

    // Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake(uint256 _tokenId) public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "PioneerParentStaking._unstake: Sender must have staked tokenID"
        );
        _unstake(msg.sender, _tokenId);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }


    /// @notice Returns the about of rewards yet to be claimed
    function unclaimedRewards(
        address _user
    )
        external
        view
        returns(uint256)
    {
        if (stakedHashPowerTotal == 0) {
            return 0;
        }

        return rewardsController.unclaimedRewards(_user);
    }


    /// @notice Lets a user with rewards owing to claim tokens
    function claimReward() external
    {
        require(
            tokensClaimable == true,
            "Tokens cannnot be claimed yet"
        );
    
        uint256 rewardAmmount = rewardsController.harvest(msg.sender);

        /// Sanity check for dust in balance (when the balance in the contract is lower than the due rewards)
        uint256 rewardBal = rewardsToken.balanceOf(address(this));
        if (rewardAmmount > rewardBal) {
            rewardAmmount = rewardBal;
        }

        rewardsToken.transfer(msg.sender, rewardAmmount);
        emit RewardPaid(msg.sender, rewardAmmount);
    }

    function _removeStakedToken(address _user, uint _tokenId) internal {
        Staker storage staker = stakers[_user];
        for(uint i = 0; i < staker.tokenIds.length -1; i++) {
            if(staker.tokenIds[i] == _tokenId) {
                staker.tokenIds[i] = staker.tokenIds[staker.tokenIds.length - 1];
                staker.tokenIds.pop();
                break;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    )
        public returns(bytes4)
    {
        return _ERC721_RECEIVED;
    }
}