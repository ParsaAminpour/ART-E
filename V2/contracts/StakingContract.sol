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

// @author <a href="mailto:parsa.aminpour@gmail.com"> ParsaAminpour </a>
contract StakingContract is Ownable, ReentrancyGuard, AccessControl {
    using Address for address;
    using Math for uint256;


    error StakingContract__NoStakedBefore();

    struct stake_workflow_status {
        uint256 last_time_update;
        uint256 total_staked;
    }

    IERC1155 public tokenReward;
    IERC721 public arte_nft;
    stake_workflow_status public workflow; // should be internal
    uint256 internal top_share_amount; 
    uint8 public immutable const_reward; // should be private


    event withdraw_event(address indexed _staker, uint indexed _amount);
    event stake_event(address indexed _staker, uint indexed _amount);
    event withdraw_reward_event(address indexed _staker, uint indexed _amount);


    // staker address  => (ARTE1155 tokenId => amount staked)
    // mapping(address => mapping(uint256 => uint256)) private userTokenReward;
    mapping(address => uint256) private userTokenReward;
    mapping(address => uint256) private reward_balance;
    mapping(address => bool) private isTopShares;


    /*
    @param _tokenReward which is the reward NFT token that we will distribute
    @param _reward_amount is the amount to distribute between share holders per day
    */
    constructor(IERC721 _nft_contract ,IERC1155 _tokenReward, uint8 _reward_amount) Ownable(msg.sender) {
        arte_nft = _nft_contract;
        tokenReward = _tokenReward;

        workflow = stake_workflow_status(
            block.timestamp, 1); // init total_staked 

        const_reward = _reward_amount;
    }



    modifier AssetModifier(address _staker) { _; }




    // update the current token reward to token reward based on the efficient algorithm which
    // explained in this link <link>
    function update_user_token_reward() public view returns(uint256 result){
        // console.log(workflow.total_staked);
        // console.log(const_reward);
        // console.log(block.timestamp);
        // console.log(workflow.last_time_update);

        // console.log("////");
        uint256 first = ((const_reward * 1e18) / (workflow.total_staked));
        // console.log(first);
        uint256 second = (block.timestamp - workflow.last_time_update);
        // console.log(second);
        result = first * second;
        // console.log(result);
    }


    /*
    @dev this function will update the stake algorithm status workflow and adding the balance belongs share-holder.
    @dev in this staking algorithm, Staking and Withdrawing operations are significatn point in the histogram plot.
    @param _staker is the address os wallet which staked the nft
    @return _new_balance is the new reward balance of ARTE1155 
    */
    function Staking(address _staker, uint8 _tokenId)
    external 
    nonReentrant()
    returns(uint256 _new_balance) {
        require(arte_nft.ownerOf(_tokenId) == _staker, "staker must be the owner of the token");
        // require(_amount > 0, "amount must be more than 0");

        // update user reward per token
        userTokenReward[_staker] =
            userTokenReward[_staker] + 
                update_user_token_reward();
        // console.log(userTokenReward[_staker]);

        workflow.last_time_update = block.timestamp;
        workflow.total_staked ++;

        // Will be used in calculating final reward in terms of _balance * (rf - ri)                
        reward_balance[_staker] ++;

        // the bug relates to modify top_share_amount in withdraw will be solved ASAP
        top_share_amount =  top_share_amount < reward_balance[_staker] 
            ? reward_balance[_staker] : top_share_amount;


        _new_balance = reward_balance[_staker];
    }

    /*
    @dev this function will update the stake algorithm status workflow and adding the balance belongs share-holder.
    @dev in this staking algorithm, Staking and Withdrawing operations are significatn point in the histogram plot.
    @param _staker is the address os wallet which staked the nft
    @param _nftStaked is the number of nft contract which staked
    @param _amount is the amount of staked to the nft contract (_nftStaked)
    */
    function Witdrawing(address _staker, uint256 _amount)
    external
    nonReentrant()
    returns(uint256 _remained_balance) {
        require(userTokenReward[_staker] > 0, "NFT contract address is invalid or insufficient balance");
        require(reward_balance[_staker] > 0, "You have not already own stake balance in this contract");
        require(_amount > 0, "You have not already");

        workflow.total_staked -= _amount;
        workflow.last_time_update = block.timestamp;

        userTokenReward[_staker] = 
            userTokenReward[_staker] + 
                update_user_token_reward();

        reward_balance[_staker] -= _amount;
        _remained_balance = reward_balance[_staker];
    }






    function getBalance(address _share_holder) public view returns(uint256 share) {
        share = reward_balance[_share_holder];
    }

    function calculateReward(stake_workflow_status calldata _workflow) 
    public
    returns(uint256 result) {}

    function earnReward() external nonReentrant{
        _earnReward();
    }

    function _earnReward() private {
        // calculating reward based on Stake reward algorithm
    }



    // Getting private state variables status
    function getUserTokenPerReward(
        address _staker
    ) public view returns(uint256 reward_amount) {
        reward_amount = userTokenReward[_staker];
    }

    function getIsTopShare(address _staker) public view returns(bool _is) {
        _is = isTopShares[_staker];
    }
}