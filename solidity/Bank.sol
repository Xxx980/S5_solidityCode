// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBank.sol";

contract Bank is IBank {
    // 存储每个地址的存款金额
    mapping(address => uint256) public deposits;
    
    // 存储前3名用户的地址
    address[] internal  topUsers;
    // 存储前3名用户的存款金额
    uint256[] internal topDeposits;
    
    // 管理员地址
    address public admin;
    
    // 构造函数，设置合约部署者为管理员
    constructor() {
        admin = msg.sender;
    }
    
    // 存款函数
    receive() external payable virtual  {
        if (msg.value <= 0) {
            return;
        }

        deposits[msg.sender] += msg.value;
        updateTopUsers(msg.sender, deposits[msg.sender]);
    }

    // 提现函数，只有管理员可以调用
    function withdraw() external virtual  {
        require(msg.sender == admin, "Only the admin can withdraw");
        payable(admin).transfer(address(this).balance);
    }

    // 更新前3名存款最多的用户
    function updateTopUsers(address user, uint256 depositAmount) internal {
        bool isUpdated = false;
        
        // 遍历前3名存款记录，找到合适的位置插入新存款金额
        for (uint i = 0; i < 3; i++) {
            if (topUsers.length <= i || depositAmount > topDeposits[i]) {
                if (topUsers.length == 3) {
                    topUsers.pop();
                    topDeposits.pop();
                }
                topUsers.push(user);
                topDeposits.push(depositAmount);
                isUpdated = true;
                break;
            }
        }

        if (isUpdated) {
            sortTopUsers();
        }
    }

    // 排序前3名用户
    function sortTopUsers() internal {
        for (uint i = 0; i < topDeposits.length; i++) {
            for (uint j = i + 1; j < topDeposits.length; j++) {
                if (topDeposits[i] < topDeposits[j]) {
                    uint256 tempDeposit = topDeposits[i];
                    topDeposits[i] = topDeposits[j];
                    topDeposits[j] = tempDeposit;
                    
                    address tempUser = topUsers[i];
                    topUsers[i] = topUsers[j];
                    topUsers[j] = tempUser;
                }
            }
        }
    }

    // 获取前3名用户及其存款金额
    function getTopUsers() external view override returns (address[] memory, uint256[] memory) {
        return (topUsers, topDeposits);
    }
}
