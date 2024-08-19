// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interface/IStaking.sol";
import "hardhat/console.sol";

/**
 * @title stkaing contract
 * @author stonej
 * @notice Staking contract
 *  1. Staking
 *  2. Reward = 0.1B / 1 year ,  8M / 4 week
 *  3. withdraw = 4 week
 *  
 *  */ 
abstract contract Staking is IStaking{

    using SafeERC20 for IERC20;
    using Math for uint256;

    IERC20 private immutable token;
    uint256 private totalDeposit;
    StaingOp private op;

    constructor( IERC20 _token , 
                bool _isFiexedRate , 
                uint256 _rate , 
                uint256 _rewardTime,
                uint256 _rewardByTime,
                uint256 _startTime ) {
        token = _token;
        
        op.rateInfo = _isFiexedRate ? StakingRewardOp.fixedRate : 
                                      StakingRewardOp.timeRate;
        op.fiexdRate = _rate;
        op.rewardTime = _rewardTime;  // default = 2 weeks
        op.rewardByTime = _rewardByTime;
        op.startTime = _startTime;
    }

    mapping ( address => UserInfo ) private userStakingInfo;

    /* 2 Weeks = index
     * Total_Deposit per index
     */
    mapping ( uint256 => uint256 ) private totalDepositByTime;

    mapping ( address => mapping (uint256 => uint256)) private userStakingByTime;

    function staking ( uint256 _amount ) external virtual{}

    function _staking ( address _sender , uint256 _amount ) internal {

        require ( _amount > 0 , "staking amount error");

        token.safeTransferFrom(_sender , address(this) , _amount);
         
        if (userStakingInfo[_sender].stakingAmount > 0 ) {

            uint256 reward = userCalReward(_sender);

            if (reward != 0) {
                userStakingInfo[_sender].calReward += reward;
            }
        } else {
            userStakingInfo[_sender].theFistTime = block.timestamp;
        }

        if( totalDepositByTime[_getIndexByTime()] == 0 ) {
            totalDepositByTime[_getIndexByTime()] = totalDeposit;
        }

        userStakingInfo[_sender].indexByTime = _getIndexByTime();
        userStakingInfo[_sender].stakingAmount += _amount;

        userStakingByTime[_sender][_getIndexByTime()] = userStakingInfo[_sender].stakingAmount;
    

        totalDeposit += _amount;
        totalDepositByTime[_getIndexByTime()] += _amount;

        emit depositEvent(_sender , _amount);
    }

    function unStaking ( uint256 _amount ) external virtual{}

    function _unStaking ( address _sender , uint256 _amount ) internal {
        require ( userStakingInfo[_sender].stakingAmount >= _amount , "");

        userStakingInfo[_sender].stakingAmount -= _amount;
        userStakingInfo[_sender].indexByTime = _getIndexByTime();
        totalDeposit -= _amount;

        uint256 reward = userCalReward(_sender);

        userStakingByTime[_sender][_getIndexByTime()] = userStakingInfo[_sender].stakingAmount;

        userStakingInfo[_sender].calReward += reward;

        if (userStakingInfo[_sender].stakingAmount == 0) {
            userStakingInfo[_sender].theFistTime = 0;
        }

        token.safeTransfer( _sender, _amount);

        emit withdrawEvent(_sender, _amount);
    }
    
    function rewardClaim (  ) external virtual{}

    function _rewardClaim (address _sender) internal {
        
        uint256 reward = userCalReward(_sender);

        reward += userStakingInfo[_sender].calReward;

        require (reward > 0 , "");

        userStakingInfo[_sender].calReward = 0;

        token.safeTransfer( _sender, reward);

        emit rewardClaimEvent(_sender , reward , block.timestamp );
    }
    
    function getUserDeposit ( address _sender ) 
        external view returns ( uint256) {

        return userStakingInfo[_sender].stakingAmount;            
    }

    function userCalReward ( address _staker ) 
        internal view returns (uint256 ) {
        
        return  
            (op.rateInfo == StakingRewardOp.fixedRate) ? 
            fiexedCalReward( _staker ) : userTimeCalReward( _staker );
    }

    function fiexedCalReward ( address _staker ) 
        internal view returns (uint256) {}

    function userTimeCalReward ( address _staker ) 
        internal view returns (uint256) {

        uint256 currentIndex = _getIndexByTime();

        if ( currentIndex == 0 || currentIndex == userStakingInfo[_staker].indexByTime ) {
            return 0;    
        } 
        
        uint256 tmpTotal = totalDepositByTime[userStakingInfo[_staker].indexByTime];
        uint256 tmpUserStaking = userStakingByTime[_staker][userStakingInfo[_staker].indexByTime];
        uint256 reward;
        
        for ( uint256 i = userStakingInfo[_staker].indexByTime ; 
                i < currentIndex ; 
                i++) 
        {   
            if (i == userStakingInfo[_staker].indexByTime ) {
                reward += (userStakingByTime[_staker][i] * (op.rewardByTime)) / tmpTotal;
            } else {
                uint256 tmpT ; uint256 tmpU;    

                if ( totalDepositByTime[i] == 0 ) tmpT = tmpTotal;
                else tmpT = totalDepositByTime[i];
                if ( userStakingByTime[_staker][i] == 0) tmpU = tmpUserStaking;
                else tmpU = userStakingByTime[_staker][i];

                reward += (tmpU * op.rewardByTime) / tmpT;
            
            }
        }
        return reward ;
    }

    function getCurrentIndex () external view returns ( uint256 ) {
        return _getIndexByTime();
    } 

    function getUserInfo ( address _sender ) external view returns (UserInfo memory) {
        return userStakingInfo[_sender];
    }

    function getUserReward ( address _staker ) external view returns (uint256) {
        
        if ( userStakingInfo[_staker].theFistTime + op.rewardTime > block.timestamp) {
            return 0;
        }

        return userTimeCalReward(_staker) + userStakingInfo[_staker].calReward;
    }

    function getTotalByTime(uint256 _index) external view returns ( uint256 ) {
        return totalDepositByTime[_index];
    }

    function getUnStakingTime ( address _sender ) external view returns ( uint256 ) {
        return userStakingInfo[_sender].theFistTime + op.rewardTime;
    }

    function _getIndexByTime () internal view returns ( uint256 ) {
        return ( block.timestamp - op.startTime ) / op.rewardTime;   
    }

}