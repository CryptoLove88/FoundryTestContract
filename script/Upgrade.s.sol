// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/StakingContractV2.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new implementation
        StakingContractV2 newImplementation = new StakingContractV2();
        console.log("New implementation deployed at:", address(newImplementation));

        // 2. Get proxy address from environment
        address proxyAddress = vm.envAddress("STAKING_CONTRACT_ADDRESS");
        console.log("Proxy address:", proxyAddress);

        // 3. Upgrade proxy to new implementation
        // Note: This assumes the proxy has an upgrade function
        // You might need to adjust this based on your proxy implementation
        (bool success,) = proxyAddress.call(
            abi.encodeWithSignature("upgradeTo(address)", address(newImplementation))
        );
        require(success, "Upgrade failed");
        console.log("Upgrade completed successfully");

        // 4. Test new function
        uint256 randomNumber = StakingContractV2(proxyAddress).getRandomNumber();
        console.log("New function test - Random number:", randomNumber);

        vm.stopBroadcast();
    }
} 