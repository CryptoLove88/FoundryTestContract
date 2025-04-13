// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/StakingContract.sol";
import "../src/SHMToken.sol";
import "../src/SCBToken.sol";

contract StakingContractTest is Test {
    StakingContract public stakingContract;
    SHMToken public shmToken;
    SCBToken public scbToken;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy tokens
        shmToken = new SHMToken();
        scbToken = new SCBToken();

        // Deploy staking contract using proxy pattern
        StakingContract implementation = new StakingContract();
        bytes memory initData = abi.encodeWithSelector(StakingContract.initialize.selector);
        stakingContract = StakingContract(deployProxy(address(implementation), initData));

        // Setup staking contract
        stakingContract.setStakingToken(address(shmToken));
        stakingContract.setRewardToken(address(scbToken));
        stakingContract.setRewardSource(owner);
        stakingContract.setRewardPerBlock(1e18);

        // Mint tokens for testing
        shmToken.mint(user1, 1000e18);
        shmToken.mint(user2, 1000e18);
        scbToken.mint(owner, 10000e18);

        // Approve tokens
        scbToken.approve(address(stakingContract), type(uint256).max);
        
        vm.startPrank(user1);
        shmToken.approve(address(stakingContract), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        shmToken.approve(address(stakingContract), type(uint256).max);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(address(stakingContract.stakingToken()), address(shmToken));
        assertEq(address(stakingContract.rewardToken()), address(scbToken));
        assertEq(stakingContract.rewardSource(), owner);
        assertEq(stakingContract.rewardPerBlock(), 1e18);
    }

    function testStaking() public {
        vm.startPrank(user1);
        stakingContract.deposit(100e18);
        (uint256 stakedAmount,) = stakingContract.getBalance(user1);
        assertEq(stakedAmount, 100e18);
        vm.stopPrank();
    }

    // Helper function to deploy proxy
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