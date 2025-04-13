// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/StakingContract.sol";
import "../src/SHMToken.sol";
import "../src/SCBToken.sol";

contract VerifyScript is Script {
    function run() external {
        // Get deployed contract addresses from environment variables
        address shmTokenAddress = vm.envAddress("SHM_TOKEN_ADDRESS");
        address scbTokenAddress = vm.envAddress("SCB_TOKEN_ADDRESS");
        address stakingContractAddress = vm.envAddress("STAKING_CONTRACT_ADDRESS");

        console.log("Contract addresses to verify:");
        console.log("SHMToken:", shmTokenAddress);
        console.log("SCBToken:", scbTokenAddress);
        console.log("StakingContract:", stakingContractAddress);
        
        console.log("\nTo verify these contracts, run the following commands:");
        console.log("--------------------------------------------------");
        console.log("forge verify-contract", vm.toString(shmTokenAddress), "SHMToken --chain-id 17000 --watch");
        console.log("forge verify-contract", vm.toString(scbTokenAddress), "SCBToken --chain-id 17000 --watch");
        console.log("forge verify-contract", vm.toString(stakingContractAddress), "StakingContract --chain-id 17000 --watch");
        console.log("--------------------------------------------------");
    }
} 