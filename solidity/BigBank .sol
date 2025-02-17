// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bank.sol";  // 引入 Bank 合约

contract BigBank is Bank {
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    modifier minimumDeposit(uint256 amount) {
        require(amount >= MIN_DEPOSIT, "Deposit must be greater than 0.001 ETH");
        _;
    }

    receive() external payable override minimumDeposit(msg.value) {
        deposits[msg.sender] += msg.value;
        updateTopUsers(msg.sender, deposits[msg.sender]);
    }

    // 转移管理员权限给新的地址
    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only the current admin can transfer admin rights");
        admin = newAdmin;  // 将管理员地址转移给新的地址
    }
}
