// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingContract is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    // Staking token and reward token
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    address public rewardSource;

    // Staking parameters
    uint256 public rewardPerBlock;
    uint256 public totalStaked;
    uint256 public lastUpdateBlock;
    
    // Calculation precision factor
    uint256 private constant PRECISION_FACTOR = 1e12;
    
    // Accumulated reward per share (scaled value)
    uint256 public accRewardPerShare;

    // Staking information for each user
    struct UserInfo {
        uint256 amount;           // Staked amount
        uint256 rewardDebt;       // Reward debt
    }

    // Mapping from user address to their staking information
    mapping(address => UserInfo) public userInfo;

    // Events
    event StakingTokenSet(address indexed token);
    event RewardTokenSet(address indexed token);
    event RewardSourceSet(address indexed source);
    event RewardPerBlockSet(uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event WithdrawOrHarvest(address indexed user, uint256 stakedAmount, uint256 rewardAmount, bool isFullWithdrawal);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /// @custom:oz-upgrades-unsafe-allow-constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        lastUpdateBlock = block.number;
    }

    /**
     * @dev Set the token that can be staked
     * @param _token Address of the staking token
     */
    function setStakingToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        stakingToken = IERC20(_token);
        emit StakingTokenSet(_token);
    }

    /**
     * @dev Set the token used for rewards
     * @param _token Address of the reward token
     */
    function setRewardToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        rewardToken = IERC20(_token);
        emit RewardTokenSet(_token);
    }

    /**
     * @dev Set the source address for reward distribution
     * @param _source Address of the reward source
     */
    function setRewardSource(address _source) external onlyOwner {
        require(_source != address(0), "Invalid source address");
        rewardSource = _source;
        emit RewardSourceSet(_source);
    }

    /**
     * @dev Set the reward amount per block
     * @param _amount Amount of rewards per block
     */
    function setRewardPerBlock(uint256 _amount) external onlyOwner {
        // Update accumulated rewards before changing the reward rate
        updatePool();
        rewardPerBlock = _amount;
        emit RewardPerBlockSet(_amount);
    }

    /**
     * @dev Update staking pool state
     */
    function updatePool() public {
        // 상태 변수에 대한 반복 접근 줄이기
        uint256 _lastUpdateBlock = lastUpdateBlock;
        
        if (block.number <= _lastUpdateBlock) {
            return;
        }

        uint256 _totalStaked = stakingToken.balanceOf(address(this));
        if (_totalStaked == 0) {
            lastUpdateBlock = block.number;
            return;
        }

        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        uint256 rewards = blocksSinceLastUpdate * rewardPerBlock;
        
        accRewardPerShare = accRewardPerShare + (rewards * PRECISION_FACTOR / _totalStaked);
        lastUpdateBlock = block.number;
    }

    function _safeTransferReward(address _to, uint256 _amount) internal {
        require(address(rewardToken) != address(0), "Reward token not set");
        require(rewardSource != address(0), "Reward source not set");
        rewardToken.safeTransferFrom(rewardSource, _to, _amount);
    }

    /**
     * @dev Stake tokens
     * @param _amount Amount of tokens to stake
     */
    function deposit(uint256 _amount) external {
        require(address(stakingToken) != address(0), "Staking token not set");
        require(_amount > 0, "Amount must be greater than 0");

        // Get user info
        UserInfo storage user = userInfo[msg.sender];

        // Update pool state
        updatePool();
        
        if (user.amount > 0) {
            // Calculate pending rewards
            uint256 pendingReward = 0;
            pendingReward = (user.amount * accRewardPerShare / PRECISION_FACTOR) - user.rewardDebt;

            if (pendingReward > 0) {
                _safeTransferReward(msg.sender, pendingReward);
            }
        }
        
        if (_amount > 0) {
            // Transfer staking tokens from user to contract
            stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
            user.amount += _amount;
            user.rewardDebt = user.amount * accRewardPerShare / PRECISION_FACTOR;
        }

        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraw staked tokens and rewards
     */
    function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _stakedAmount = user.amount;
        
        require(_stakedAmount > 0, "No staked tokens");
        require(rewardSource != address(0), "Reward source not set");

        // Update pool state
        updatePool();

        // Calculate pending rewards
        uint256 pendingReward = (_stakedAmount * accRewardPerShare / PRECISION_FACTOR) - user.rewardDebt;
        if (pendingReward > 0) {
            _safeTransferReward(msg.sender, pendingReward);
        }

        if (_stakedAmount > 0) {
            // Transfer staked tokens back to user
            stakingToken.safeTransfer(msg.sender, _stakedAmount);
            user.amount = 0;
            user.rewardDebt = 0;
        }
    }

    /**
     * @dev Get user's staked balance and pending rewards
     * @param _user Address of the user
     * @return stakedAmount Amount of staked tokens
     * @return pendingRewards Amount of pending rewards
     */
    function getBalance(address _user) external view returns (uint256 stakedAmount, uint256 pendingRewards) {
        UserInfo storage user = userInfo[_user];
        stakedAmount = user.amount;
        
        // Calculate current accumulated rewards (updated value)
        uint256 _accRewardPerShare = accRewardPerShare;
        uint256 _lastUpdateBlock = lastUpdateBlock;
        uint256 _totalStaked = totalStaked;
        
        if (block.number > _lastUpdateBlock && _totalStaked > 0) {
            uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
            uint256 rewards = blocksSinceLastUpdate * rewardPerBlock;
            _accRewardPerShare = _accRewardPerShare + (rewards * PRECISION_FACTOR / _totalStaked);
        }
        
        // Calculate pending rewards
        if (stakedAmount > 0) {
            pendingRewards = (stakedAmount * _accRewardPerShare / PRECISION_FACTOR) - user.rewardDebt;
        } else {
            pendingRewards = 0;
        }
    }
} 