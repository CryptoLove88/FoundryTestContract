// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/StakingContract.sol";
import "../src/SHMToken.sol";
import "../src/SCBToken.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts from address:", deployer);
        
        // Set gas price and limit
        vm.txGasPrice(3000000000); // 3 gwei
        vm.setEnv("FOUNDRY_PROFILE", "default");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy tokens
        console.log("Deploying SHMToken...");
        SHMToken shmToken = new SHMToken();
        console.log("SHMToken deployed at:", address(shmToken));
        
        console.log("Deploying SCBToken...");
        SCBToken scbToken = new SCBToken();
        console.log("SCBToken deployed at:", address(scbToken));

        // 2. Deploy ProxyAdmin
        console.log("Deploying ProxyAdmin...");
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployer);
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        // 3. Deploy implementation
        console.log("Deploying StakingContract implementation...");
        StakingContract implementation = new StakingContract();
        console.log("Implementation deployed at:", address(implementation));

        // 4. Deploy proxy
        console.log("Deploying TransparentUpgradeableProxy...");
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            abi.encodeWithSelector(StakingContract.initialize.selector)
        );
        console.log("Proxy deployed at:", address(proxy));

        // 5. Get StakingContract instance at proxy address
        StakingContract stakingContract = StakingContract(address(proxy));

        // 6. Setup staking contract
        console.log("Setting up staking contract...");
        stakingContract.setStakingToken(address(shmToken));
        stakingContract.setRewardToken(address(scbToken));
        stakingContract.setRewardSource(deployer);
        stakingContract.setRewardPerBlock(1e18);

        // 7. Mint initial tokens
        console.log("Minting initial tokens...");
        shmToken.mint(deployer, 1000000e18);
        scbToken.mint(deployer, 1000000e18);

        // 8. Approve tokens
        console.log("Setting token approvals...");
        shmToken.approve(address(stakingContract), type(uint256).max);
        scbToken.approve(address(stakingContract), type(uint256).max);
        
        vm.stopBroadcast();

        console.log("\nDeployment completed successfully!");
        console.log("-----------------------------------");
        console.log("SHMToken:", address(shmToken));
        console.log("SCBToken:", address(scbToken));
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));
    }
} 