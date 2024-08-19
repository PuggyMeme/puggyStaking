// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IStaking {

    enum StakingRewardOp { fixedRate , timeRate}
    
    struct StaingOp {
        StakingRewardOp rateInfo;
        uint256 fiexdRate ; /** fixed Rate Percent */
        uint256 rewardTime;
        uint256 rewardByTime;
        uint256 startTime;
    }
    
    struct UserInfo {
        uint256 stakingAmount;
        uint256 calReward;
        uint256 indexByTime;
        uint256 theFistTime;
    }

    event depositEvent (address , uint256);
    event withdrawEvent ( address , uint256 );
    event rewardClaimEvent ( address , uint256 , uint256 );
}
