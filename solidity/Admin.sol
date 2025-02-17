// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBank.sol";  // 引入 IBank 接口

contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender;  // 合约创建者为 admin
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // 修改管理员
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // 从 BigBank 合约提取资金
    function adminWithdraw(IBank BigBank) external onlyOwner {
        // 调用传入的 Bank 合约的 withdraw 方法
        BigBank.withdraw();  // 调用 BigBank 的 withdraw 函数

        // 提取的资金将转移到 Admin 合约的 owner 地址
        payable(owner).transfer(address(this).balance);  // 将资金发送到 Admin 合约的 owner 地址
    }
}
