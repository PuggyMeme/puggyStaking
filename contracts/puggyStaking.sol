// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Staking.sol";
import "hardhat/console.sol";

contract puggyStaking  is Staking{

    IERC20 private immutable token;

    constructor (IERC20 _token) Staking(_token , 
                                        false , 
                                        0 , 
                                        4 weeks , 
                                        8000000*1e18 , 
                                        block.timestamp){
        token = _token;
    }
    
    function staking ( uint256 _amount ) external override {
        _staking(msg.sender, _amount);
    }
    function unStaking ( uint256 _amount ) external override {
        _unStaking(msg.sender , _amount);
    }
    function rewardClaim () external override {
        _rewardClaim(msg.sender);
    }

}









