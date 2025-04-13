// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/StakingContract.sol";
import "../src/SHMToken.sol";
import "../src/SCBToken.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts from address:", deployer);
        
        // Set gas price and limit
        vm.txGasPrice(3000000000); // 3 gwei
        vm.setEnv("FOUNDRY_PROFILE", "default");
        
        // Deploy tokens
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying SHMToken...");
        SHMToken shmToken = new SHMToken();
        console.log("SHMToken deployed at:", address(shmToken));
        
        console.log("Deploying SCBToken...");
        SCBToken scbToken = new SCBToken();
        console.log("SCBToken deployed at:", address(scbToken));

        // Deploy staking contract implementation
        console.log("Deploying StakingContract implementation...");
        StakingContract implementation = new StakingContract();
        bytes memory initData = abi.encodeWithSelector(StakingContract.initialize.selector);
        StakingContract stakingContract = StakingContract(deployProxy(address(implementation), initData));
        console.log("StakingContract deployed at:", address(stakingContract));

        // Setup staking contract
        console.log("Setting up staking contract...");
        stakingContract.setStakingToken(address(shmToken));
        stakingContract.setRewardToken(address(scbToken));
        stakingContract.setRewardSource(deployer);
        stakingContract.setRewardPerBlock(1e18);

        // Mint initial tokens
        console.log("Minting initial tokens...");
        shmToken.mint(deployer, 1000000e18);
        scbToken.mint(deployer, 1000000e18);

        // Approve tokens
        console.log("Setting token approvals...");
        shmToken.approve(address(stakingContract), type(uint256).max);
        scbToken.approve(address(stakingContract), type(uint256).max);
        
        vm.stopBroadcast();

        console.log("\nDeployment completed successfully!");
        console.log("-----------------------------------");
        console.log("SHMToken:", address(shmToken));
        console.log("SCBToken:", address(scbToken));
        console.log("StakingContract:", address(stakingContract));
    }

    function deployProxy(address implementation, bytes memory initData) internal returns (address) {
        bytes memory deploymentData = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );

        address proxy;
        assembly {
            proxy := create(0, add(deploymentData, 0x20), mload(deploymentData))
        }

        (bool success,) = proxy.call(initData);
        require(success, "Proxy initialization failed");

        return proxy;
    }
} 