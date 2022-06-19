// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ParticleStaking is Ownable, ReentrancyGuard {
    address private _owner;
    uint256 constant MIN_REWARD_RATE = 365 * 8;
    uint256 constant MAX_REWARD_RATE = 365 * 12;
    uint256 public startTime;
    uint256 public stakeholderCount;
    mapping(address => Stakeholder) public stakeholders;

    struct Stakeholder {
        address addr;
        uint256 referred;
        Rebate rebate;
        Stake[] stakes;
    }

    struct Rebate {
        uint256 amount;
        uint256 claimed;
    }

    struct Stake {
        uint256 rewardRate;
        uint256 amount;
        uint256 claimed;
        uint256 createdAt;
    }

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyStakeholder() {
        require(isStakeholder(msg.sender), "ParticleStaking: caller is not the stakeholder");
        _;
    }

    modifier onlyOpened() {
        require(startTime > 0, "ParticleStaking: event is not opened yet");
        _;
    }

    modifier onlyStarted() {
        require(block.timestamp > startTime, "ParticleStaking: event is not started yet");
        _;
    }

    function setStartTime(uint256 _startTime)
        external
        onlyOwner
    {
        require(startTime == 0, "ParticleStaking: event has already opened");
        startTime = _startTime;
    }

    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function stakesOf(address _stakeholder)
        external
        view
        onlyStakeholder
        returns (Stake[] memory)
    {
        return stakeholders[_stakeholder].stakes;
    }

    function isStakeholder(address _stakeholder)
        public
        view
        returns (bool)
    {
        return stakeholders[_stakeholder].addr != address(0);
    }

    function stake(address _referrer)
        public
        payable
        nonReentrant
        onlyOpened
    {
        require(stakeholders[msg.sender].stakes.length < 20, "ParticleStaking: maximum stake count is reached");
        if (!isStakeholder(msg.sender)) {
            stakeholders[msg.sender].addr = msg.sender;
            stakeholderCount++;
        }
        uint256 _rewardRate = calculateRewardRate(stakeholders[msg.sender].stakes.length);
        uint256 _fee = calculateFee(msg.value);
        uint256 _amount = msg.value - _fee;
        uint256 _createdAt = block.timestamp;
        if (block.timestamp < startTime) {
            _createdAt = startTime;
        }
        stakeholders[msg.sender].stakes.push(Stake({
            rewardRate: _rewardRate,
            amount: _amount,
            claimed: 0,
            createdAt: _createdAt
        }));
        if (_referrer == msg.sender || !isStakeholder(_referrer)) {
            stakeholders[_owner].rebate.amount += calculateRebate(_amount);
            stakeholders[_owner].referred += 1;
        } else {
            stakeholders[msg.sender].rebate.amount += calculateRebate(_amount);
            stakeholders[_referrer].rebate.amount += calculateRebate(_amount);
            stakeholders[_referrer].referred += 1;
        }
        payable(_owner).transfer(_fee);
    }

    function claim()
        public
        payable
        nonReentrant
        onlyStakeholder
        onlyStarted
    {
        uint256 _totalRewards;
        uint256 _totalFees;
        for (uint256 i = 0; i < stakeholders[msg.sender].stakes.length; i++) {
            uint256 _reward = calculateReward(stakeholders[msg.sender].stakes[i]);
            uint256 _fee = calculateFee(_reward);
            stakeholders[msg.sender].stakes[i].claimed += _reward - _fee;
            _totalRewards += _reward;
            _totalFees += _fee;
        }
        uint256 _rebate = stakeholders[msg.sender].rebate.amount;
        stakeholders[msg.sender].rebate.amount = 0;
        stakeholders[msg.sender].rebate.claimed += _rebate;
        uint256 _amount = _totalRewards - _totalFees + _rebate;
        payable(_owner).transfer(_totalFees);
        payable(msg.sender).transfer(_amount);
    }

    function calculateReward(Stake memory _stake)
        private
        view
        returns (uint256)
    {
        return (block.timestamp - _stake.createdAt) * _stake.amount * _stake.rewardRate / 100 / 365 days - _stake.claimed;
    }

    function calculateRewardRate(uint256 _level)
        private
        pure
        returns (uint256)
    {
        uint256 _rewardRate = MIN_REWARD_RATE * (105 ** _level) / (100 ** _level);
        return min(_rewardRate, MAX_REWARD_RATE);
    }

    function calculateRebate(uint256 _amount)
        private
        pure
        returns (uint256)
    {
        return _amount * 5 / 100;
    }

    function calculateFee(uint256 _amount)
        private
        pure
        returns (uint256)
    {
        return _amount * 3 / 100;
    }

    function min(uint256 _a, uint256 _b)
        private
        pure
        returns (uint256)
    {
        return _a < _b ? _a : _b;
    }
}
