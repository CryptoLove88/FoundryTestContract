// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StakingContract.sol";

contract StakingContractV2 is StakingContract {
    function getRandomNumber() public pure returns (uint256) {
        return 42; // 간단한 랜덤 숫자 반환
    }
} 