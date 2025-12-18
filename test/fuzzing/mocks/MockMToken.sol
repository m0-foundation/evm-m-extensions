// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockM {
    uint128 public currentIndex;
    uint32 public earnerRate;
    uint128 public latestIndex;
    uint40 public latestUpdateTimestamp;

    address public ttgRegistrar; //NOTE: added by fuzzer

    constructor(address ttgRegistrar_) {
        //NOTE: added by fuzzer
        ttgRegistrar = ttgRegistrar_;
    }

    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    mapping(address account => uint256 balance) public balanceOf;
    mapping(address account => bool isEarning) public isEarning;
    mapping(address => mapping(address => uint256)) public allowance;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {}

    function permit(address owner, address spender, uint256 value, uint256 deadline, bytes memory signature) external {}

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;

        return true;
    }

    function setBalanceOf(address account, uint256 balance) external {
        balanceOf[account] = balance;
    }

    function setCurrentIndex(uint128 currentIndex_) external {
        currentIndex = currentIndex_;
    }

    function setEarnerRate(uint256 earnerRate_) external {
        earnerRate = uint32(earnerRate_);
    }

    function setLatestIndex(uint128 latestIndex_) external {
        latestIndex = latestIndex_;
    }

    function setLatestUpdateTimestamp(uint256 timestamp) external {
        latestUpdateTimestamp = uint40(timestamp);
    }

    function setIsEarning(address account, bool isEarning_) external {
        isEarning[account] = isEarning_;
    }

    function startEarning() external {
        isEarning[msg.sender] = true;
    }

    function stopEarning(address account) external {
        isEarning[account] = false;
    }
}
