// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    uint256 constant REWARD_RATE = 3650;

    address private _owner;

    uint256 public stakeholderCount;
    mapping(address => Stakeholder) public stakeholders;

    struct Stakeholder {
        address addr;
        Stake[] stakes;
    }

    struct Stake {
        uint256 amount;
        uint256 claimedAt;
    }

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyStakeholder() {
        require(isStakeholder(msg.sender), "Staking: caller is not the stakeholder");
        _;
    }

    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function stakes(address _stakeholder)
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

    function deposit()
        public
        payable
        nonReentrant
    {
        if (!isStakeholder(msg.sender)) {
            stakeholders[msg.sender].addr = msg.sender;
            stakeholderCount++;
        }
        uint256 _fee = calculateFee(msg.value);
        uint256 _amount = msg.value - _fee;
        stakeholders[msg.sender].stakes.push(Stake({
            amount: _amount,
            claimedAt: block.timestamp
        }));
        payable(_owner).transfer(_fee);
    }

    function claim()
        public
        payable
        nonReentrant
        onlyStakeholder
    {
        uint256 _rewards;
        for (uint256 i = 0; i < stakeholders[msg.sender].stakes.length; i++) {
            _rewards += calculateReward(stakeholders[msg.sender].stakes[i]);
            stakeholders[msg.sender].stakes[i].claimedAt = block.timestamp;
        }
        uint256 _fee = calculateFee(_rewards);
        payable(_owner).transfer(_fee);
        payable(msg.sender).transfer(_rewards - _fee);
    }

    function calculateReward(Stake memory _stake)
        private
        view
        returns (uint256)
    {
        return (block.timestamp - _stake.claimedAt) * _stake.amount * REWARD_RATE / 100 / 365 days;
    }

    function calculateFee(uint256 _amount)
        private
        pure
        returns (uint256)
    {
        return _amount * 1 / 100;
    }

    event Deposit(address indexed _stakeholder, uint256 _amount);
    event Claim(address indexed _stakeholder, uint256 _amount);
}
