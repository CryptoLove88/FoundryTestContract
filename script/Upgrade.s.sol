// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/StakingContractV2.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address proxyAdminAddress = vm.envAddress("PROXY_ADMIN_ADDRESS");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        console.log("Upgrading contracts from address:", deployer);
        console.log("ProxyAdmin:", proxyAdminAddress);
        console.log("Proxy:", proxyAddress);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new implementation
        console.log("Deploying StakingContractV2 implementation...");
        StakingContractV2 newImplementation = new StakingContractV2();
        console.log("New implementation deployed at:", address(newImplementation));

        // 2. Upgrade proxy to new implementation
        console.log("Upgrading proxy to new implementation...");
        TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(proxyAddress));
        // proxy.upgradeToAndCall(address(newImplementation), "");

        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAddress);
        // proxyAdmin.upgrade(proxyAddress, address(newImplementation));
        proxyAdmin.upgradeAndCall(
            proxy,
            address(newImplementation),
            "" // No initialization data needed for this upgrade
        );
        console.log("Upgrade completed");

        // 3. Test new function
        // console.log("Testing new function...");
        // StakingContractV2 upgradedContract = StakingContractV2(address(proxy));
        // uint256 randomNumber = upgradedContract.getRandomNumber();
        // console.log("New function test - Random number:", randomNumber);

        // vm.stopBroadcast();

        // console.log("\nUpgrade completed successfully!");
        // console.log("-----------------------------------");
        // console.log("New Implementation:", address(newImplementation));
        // console.log("Proxy:", address(proxy));
    }
} 