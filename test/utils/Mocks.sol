// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

contract MockM {
    uint128 public currentIndex;
    uint128 public latestIndex;
    uint40 public latestUpdateTimestamp;

    mapping(address account => uint256 balance) public balanceOf;
    mapping(address account => bool isEarning) public isEarning;

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

    function transfer(address recipient, uint256 amount) external returns (bool) {
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

contract MockRateOracle {
    uint32 public earnerRate;

    function setEarnerRate(uint32 rate) external {
        earnerRate = rate;
    }
}
