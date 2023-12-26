// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";
import "./ARTE721.sol";
import "./ARTE1155.sol";

// @author <a href="mailto:parsa.aminpour@gmail.com"> ParsaAminpour </a>
contract StakingContract is Ownable, ReentrancyGuard, AccessControl {
    using Address for address;  
    using Math for uint256;


    error StakingContract__NoStakedBefore();

    struct stake_workflow_status {
        uint256 last_time_update;
        uint256 total_staked;
    }

    struct staker_last_reward {
        uint256 last_time_updated;
        uint256 last_reward;
    }

    ARTE1155 public tokenReward;
    ARTE721 public arte_nft;
    stake_workflow_status public workflow; // should be internal
    uint256 internal top_share_amount; 
    uint16 internal last_reward_per_user;
    uint8 public immutable const_reward; // should be private


    event withdraw_event(address indexed _staker, uint indexed _amount);
    event stake_event(address indexed _staker, uint indexed _amount);
    event withdraw_reward_event(address indexed _staker, uint indexed _amount);


    // staker address  => (ARTE1155 tokenId => amount staked)
    // mapping(address => mapping(uint256 => uint256)) private userTokenReward;
    mapping(address => staker_last_reward) private userTokenReward; // r

    mapping(address => uint256) private staked_balance; // balance of ARTE721

    mapping(address => uint256) private reward_amount_for_earn; // balance of ARTE1155 tokenId

    mapping(address => bool) private isTopShares; // For governance sys approach


    /*
    @param _tokenReward which is the reward NFT token that we will distribute
    @param _reward_amount is the amount to distribute between share holders per day
    */
    constructor(uint8 _reward_amount) 
    Ownable(msg.sender) 
    {
        arte_nft = new ARTE721(address(this));
        tokenReward = new ARTE1155(address(this));

        console.log(address(arte_nft));
        console.log(address(tokenReward));
        console.log("the msg.sedner is:");
        console.log(msg.sender);

        workflow = stake_workflow_status(
            block.timestamp, 1); // init total_staked 

        const_reward = _reward_amount;
    }



    modifier AssetModifier(address _staker) { _; }

    modifier OnlyStaker(address _caller) {
        if(staked_balance[_caller] == 0) {
            revert StakingContract__NoStakedBefore();
        }
        _;
    }


    /* 
    @dev update the current token reward to token reward based on the efficient algorithm which
    @dev explained in this link <link>
    @NOTE: this algorithm will be coded in Inline Assembly format ASAP.
    */
    function _update_last_time_reward() public view returns(uint256 result){
        uint256 first = ((const_reward * 1e18) / (workflow.total_staked));
        uint256 second = (block.timestamp - workflow.last_time_update);
        result = last_reward_per_user + (first * second);
    }


    /*
    @NOTE: this function will call during the ARTE721 token minting process in ARTE721 contract.
    @dev this function will update the stake algorithm status workflow and adding the balance belongs share-holder.
    @dev in this staking algorithm, Staking and Withdrawing operations are significatn point in the histogram plot.
    @param _staker is the address os wallet which staked the nft
    @return _new_balance is the new reward balance of ARTE1155 
    */
    function Staking(address _staker, uint256 _tokenId)
    external 
    nonReentrant()
    returns(uint256 _new_balance) {
        // require(arte_nft.ownerOf(_tokenId) != _staker, "staker must be the owner of the token");
        
        arte_nft.safeMint(_staker, _tokenId, "");

        // update user reward per token
        userTokenReward[_staker].last_time_updated = block.timestamp;
        userTokenReward[_staker].last_reward = _update_last_time_reward();
        // console.log(userTokenReward[_staker]);

        workflow.last_time_update = block.timestamp;
        workflow.total_staked ++;

        // Will be used in calculating final reward in terms of _balance * (rf - ri)                
        staked_balance[_staker] ++;

        // the bug relates to modify top_share_amount in withdraw will be solved ASAP
        top_share_amount =  top_share_amount < staked_balance[_staker] 
            ? staked_balance[_staker] : top_share_amount;


        _new_balance = staked_balance[_staker];
    }



    function safeStateChanging() private returns(bool) {}



    /*
    NOTE: this function will call during the ARTE721 token transfering process in ARTE721 contract.
        This function will just modifying algorithm states.

    @dev this function will update the stake algorithm status workflow and removing the balance belongs share-holder.
    @dev in this staking algorithm, Withdrawing operations is either a significatn point in the histogram plot.
    @dev in this function the user could just withdraw his whole balance from the contract to avoiding calculating 
        compromised calculation, because it's just a training project. 
    @param _staker is the address os wallet which staked the nft
    @return _remained_balance
    */
    function Withdrawing(
        address _staker,
        uint256 _token_id
        ) external nonReentrant() OnlyStaker(_staker) returns(bool succeed) {

        require(arte_nft.ownerOf(_token_id) == _staker, "You are not owner of this tokenId");
        require(userTokenReward[_staker].last_reward > 0, "You have not been included to this staking smart contract yet");

        // calculate reward
        bool result = calculate_reward(_staker);
        require(result, "reward calculation crashed to some problem");

        arte_nft.safeTransferFrom(_staker, address(0), _token_id);

        // updating workflow
        workflow.last_time_update = block.timestamp;
        workflow.total_staked --;

        // change userTokenReward
        userTokenReward[_staker].last_reward  = _update_last_time_reward();
        userTokenReward[_staker].last_time_updated = workflow.last_time_update;

        // change stakedBalance
        staked_balance[_staker] --;
        succeed = true;
    }


    /*
    @dev the _staker can call this function to get its reward.
    @dev the optimized and summerized calculation is the 
        (_staker reward balance) * (current time - last time _staker change ths workflow)   
    @param _staker is the reward owner
    @return success is the function accomplished status3 
    NOTE: this function will use ARTE1155 smart contract to distribute the reward.
    */
    function calculate_reward(address _staker) private returns(bool succeed) {
        // updating reward_amount_for_earn
        uint256 tmp_rf = _update_last_time_reward();
        uint256 reward_calculated = staked_balance[_staker] * (
            tmp_rf - userTokenReward[_staker].last_reward
        );

        reward_amount_for_earn[_staker] += reward_calculated;
        succeed = true;
    }

    /*
    */
    function claim_reward(
        address _staker,
        uint256 _reward_token_id
    )  external nonReentrant() OnlyStaker(_staker) returns(bool result) {
        require(reward_amount_for_earn[_staker] >= 1, 
            "reward amount is less then 0, you need more reward amount to earn ARTE1155 token");

        uint256 arte1155_balance_before_transfering = tokenReward.balanceOf(_staker, _reward_token_id);
        
        reward_amount_for_earn[_staker] = 0;

        // in deployement script the owner of the ARTE1155 rewards is the contract itself.
        tokenReward.safeTransferFrom(
            address(this), _staker, _reward_token_id, reward_amount_for_earn[_staker], "");
        
        require(arte1155_balance_before_transfering < tokenReward.balanceOf(_staker, _reward_token_id),
            "Some error occurred in trasnfering ARTE1155 token");

        // state variable updating for withdrawing whole calimed reward 
        isTopShares[_staker] == false;
        result = true;
    }



    // Accesss (read-access) to mappings in contract
    // Getting private state variables status
    function getUserTokenPerReward(
        address _staker
    ) public view returns(uint256 reward_amount) {
        reward_amount = userTokenReward[_staker].last_reward;
    }


    function getBalance(address _share_holder) public view returns(uint256 share) {
        share = staked_balance[_share_holder];
    }


    function getRewardAmountForEarn(address _staker) public view returns(uint256 reward_amount) {
        reward_amount = reward_amount_for_earn[_staker];
    }


    function getIsTopShare(address _staker) public view returns(bool _is) {
        _is = isTopShares[_staker];
    }

    function getARTE721() public view returns(address) {
        return address(arte_nft);
    }

    function getARTE1155() public view returns(address) {
        return address(tokenReward);
    }
}


















































    // /*
    // NOTE: this function will call during the ARTE721 token transfering process in ARTE721 contract.
    //     This function will just modifying algorithm states.

    // @dev this function will update the stake algorithm status workflow and removing the balance belongs share-holder.
    // @dev in this staking algorithm, Withdrawing operations is either a significatn point in the histogram plot.
    // @dev in this function the user could just withdraw his whole balance from the contract to avoiding calculating 
    //     compromised calculation, because it's just a training project. 
    // @param _staker is the address os wallet which staked the nft
    // @return _remained_balance
    // */
    // function Witdrawing(address _staker) // withdraw ERC721 nft reward 
    // external
    // nonReentrant()
    // OnlyStaker(_staker)
    // returns(uint256 _remained_balance) {
    //     require(userTokenReward[_staker].last_reward > 0, "");
    //     require(staked_balance[_staker] > 0, "You have not already own stake balance in this contract");

    //     // logs
    //     console.log(userTokenReward[_staker].last_reward);
    //     console.log(staked_balance[_staker]);


    //     staker_last_reward memory staker_last_data = userTokenReward[_staker];

    //     bool result = calculate_reward(_staker, staker_last_data.last_reward);
    //     require(result, "An error occurred in eranreward function");

    //     // There is always a (x > 0) amount stored in total_staked by the contract owner                
    //     unchecked{ workflow.total_staked --; }
    //     workflow.last_time_update = block.timestamp;

    //     staked_balance[_staker] --; // because its transfering one specific NFT token.
    //     _remained_balance = staked_balance[_staker];
    // }



    // /*
    // @dev the _staker can call this function to get its reward.
    // @dev the optimized and summerized calculation is the 
    //     (_staker reward balance) * (current time - last time _staker change ths workflow)   
    // @param _staker is the reward owner
    // @return success is the function accomplished status3 
    // NOTE: this function will use ARTE1155 smart contract to distribute the reward.
    // */
    // function calculate_reward(
    //     address _staker, uint256 _last_reward
    // ) private nonReentrant() returns(bool success) {
    //     // calculating reward based on Stake reward algorithm
    //     staker_last_reward memory staker_last_data = userTokenReward[_staker];

    //     // for checking
    //     uint init_reward_amount_for_earn = reward_amount_for_earn[_staker];

    //     // optimized formula for: (balance) * (r(f) - r(i))
    //     uint256 reward_amount = staked_balance[_staker] * (
    //         userTokenReward[_staker].last_reward - _last_reward
    //     );    

    //     // reward_amount_for_earn will use in withdrawing_reward() function
    //     reward_amount_for_earn[_staker] += reward_amount;
    //     require(reward_amount_for_earn[_staker] > init_reward_amount_for_earn, "reward amount doesn't changed");

    //     require(reward_amount_for_earn[_staker] >= reward_amount, "Some function processcalculation error happened");

    //     userTokenReward[_staker].last_reward = _update_last_time_reward();
    //     userTokenReward[_staker].last_time_updated = block.timestamp;
    //     success = true;
    // }