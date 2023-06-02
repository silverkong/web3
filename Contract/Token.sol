// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Eunbeen_Token is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public saleActive;

    uint256 public constant INIT_SUP = 1000000000 * 10**18;
    uint256 public constant PRICE_OF_WHITELIST = 1 ether / 10;
    uint256 public constant PUBLIC_PRICE = 1 ether;
    uint256 public constant SRP = 1;
    uint256 public constant PERIOD = 1;

    mapping(address => bool) public wlmapping;
    mapping(address => StakeInfo) public staking_info;

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    constructor() ERC20("EunbeenToken", "EBT") {
        _mint(address(this), INIT_SUP);
    }

    function startSale(bool active) external onlyOwner {
        saleActive = active;
    }

    function addWL(address user) external onlyOwner {
        wlmapping[user] = true;
    }

    function removeWL(address user) external onlyOwner {
        wlmapping[user] = false;
    }

    function buyToken() external payable nonReentrant {
        require(saleActive, "Sale is not active");
        uint256 tokenAmount = getAmountOfToken(msg.value);
        require(tokenAmount > 0, "Invalid token amount");
        _transfer(address(this), msg.sender, tokenAmount);
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    function getAmountOfToken(uint256 ethAmount) public view returns (uint256) {
        uint256 price = wlmapping[msg.sender] ? PRICE_OF_WHITELIST : PUBLIC_PRICE;
        return (ethAmount * 10000 * (10 ** 18)).div(price);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function stake(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance for staking");
        StakeInfo storage stakeInfo = staking_info[msg.sender];
        // Add the amount to the steakInfo -> because staked
        stakeInfo.amount = stakeInfo.amount.add(amount);
        // You can retake block.timestamp when you add a steak
        stakeInfo.timestamp = block.timestamp;
        // Send tokens to this contract
        _transfer(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external {
        StakeInfo storage stakeInfo = staking_info[msg.sender];
        require(stakeInfo.amount >= amount, "Trying to unstake more than you have");
        // Received as much as the Pending Reward
        uint256 reward = pendingReward(msg.sender);
        // Removed from stakeInfo -> because of unstake
        stakeInfo.amount = stakeInfo.amount.sub(amount);
        // new timestamp
        stakeInfo.timestamp = block.timestamp;
        // transfer the staked amount
        _transfer(address(this), msg.sender, amount);
        // After that, the amount staked will be mint.
        _mint(msg.sender, reward);
    }


    function claimReward() external {
        // reward is from pendingReward
        uint256 reward = pendingReward(msg.sender);
        require(reward > 0, "No rewards available");
        StakeInfo storage stakeInfo = staking_info[msg.sender];
        stakeInfo.timestamp = block.timestamp;
        // After that, the amount staked will be mint.
        _mint(msg.sender, reward);
    }

    function pendingReward(address staker) public view returns (uint256) {
        StakeInfo memory stakeInfo = staking_info[staker];
        uint256 timeDiff = block.timestamp.sub(stakeInfo.timestamp);
        uint256 pending = stakeInfo.amount.mul(SRP).mul(timeDiff).div(PERIOD).div(100);
        return pending;
    }

    function reStake() external {
        uint256 reward = pendingReward(msg.sender);
        require(reward > 0, "No rewards available");
        StakeInfo storage stakeInfo = staking_info[msg.sender];
        stakeInfo.amount = stakeInfo.amount.add(reward);
        stakeInfo.timestamp = block.timestamp;
    }
}