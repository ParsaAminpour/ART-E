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

// @author <a href="mailto:parsa.aminpour@gmail.com"> ParsaAminpour </a>
contract StakingContract is Ownable, ReentrancyGuard, AccessControl {
    using Address for address;

    IERC1155 tokenReward;
    stake_workflow_status internal workflow;
    uint256 internal top_share_amount; 
    uint8 private immutable const_reward;

    struct stake_workflow_status {
        uint256 last_time_update;
        uint256 total_staked;
    }

    event withdraw_event(address indexed _staker, uint indexed _amount);
    event stake_event(address indexed _staker, uint indexed _amount);
    event withdraw_reward_event(address indexed _staker, uint indexed _amount);

    constructor(IERC1155 _tokenReward, uint8 _reward_amount) Ownable(msg.sender) {
        tokenReward = _tokenReward;

        workflow = stake_workflow_status(
            block.timestamp, 0);

        const_reward = _reward_amount;
    }


    // staker address  => (nft contract address => amount staked)
    mapping(address => mapping(address => uint256)) private userTokenReward;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private isTopShares;



    modifier AssetModifier(address _staker) { _; }

    /*
    @dev this function will update the stake algorithm status workflow and adding the balance belongs share-holder.
    @dev in this staking algorithm, Staking and Withdrawing operations are significatn point in the histogram plot.
    @param _staker is the address os wallet which staked the nft
    @param _nftStaked is the number of nft contract which staked
    @param _amount is the amount of staked to the nft contract (_nftStaked)
    */
    function Staking(address _staker, IERC721 _nftStaked ,uint256 _amount)
    external 
    nonReentrant()
    returns(uint256 _new_balance) {
        // update user reward per token
        userTokenReward[_staker][address(_nftStaked)] =
            userTokenReward[_staker][address(_nftStaked)] + 
                update_user_token_reward();
                
        _balances[_staker] += _amount;

        // the bug relates to modify top_share_amount in withdraw will be solved ASAP
        top_share_amount =  top_share_amount < _amount 
            ? _amount : top_share_amount;


        // update stake algorithm status
        workflow.total_staked += _amount;
        workflow.last_time_update = block.timestamp;

        _new_balance = _balances[_staker];
    }

    // update the current token reward to token reward based on the efficient algorithm which
    // explained in this link <link>
    function update_user_token_reward() public view returns(uint256 result){
        result =  (const_reward / workflow.total_staked) * (block.timestamp - workflow.last_time_update);
    }

    function Witdrawing(address _staker, IERC721 _nftStaked, uint256 _amount)
    external
    nonReentrant()
    returns(uint256 _remained_balance) {
        require(userTokenReward[_staker][address(_nftStaked)] > 0, "NFT contract address is invalid or insufficient balance");
        require(_balances[_staker] > 0, "You have not already own stake balance in this contract");
        require(_amount > 0, "You have not already");

        workflow.total_staked -= _amount;
        workflow.last_time_update = block.timestamp;

        userTokenReward[_staker][address(_nftStaked)] = 
            userTokenReward[_staker][address(_nftStaked)] + 
                update_user_token_reward();

        _balances[_staker] -= _amount;
        _remained_balance = _balances[_staker];
    }


    function getBalance(address _share_holder) public view returns(uint256 share) {
        share = _balances[_share_holder];
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
}