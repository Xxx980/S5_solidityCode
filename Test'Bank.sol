// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 存储每个地址的存款金额
    mapping(address => uint256) public deposits;
    
    // 存储前3名用户的地址
    address[] internal  topUsers;
    // 存储前3名用户的存款金额
    uint256[] internal topDeposits;
    
    // 管理员地址
    address private    admin;
    
    // 构造函数，设置合约部署者为管理员
    constructor() {
        admin = msg.sender;
    }
    
    // 使用 receive() 接收存款
    receive() external payable {
        if (msg.value <= 0) {
            // 如果存款金额小于等于0，停止执行
            return;
        }

        // 更新存款金额
        deposits[msg.sender] += msg.value;
        
        // 更新前3名用户的记录
        updateTopUsers(msg.sender, deposits[msg.sender]);
    }
    
    // 更新前3名存款最多的用户
    function updateTopUsers(address user, uint256 depositAmount) internal {
        bool isUpdated = false;
        
        // 遍历前3名存款记录，找到合适的位置插入新存款金额
        for (uint i = 0; i < 3; i++) {
            if (topUsers.length <= i || depositAmount > topDeposits[i]) {
                // 插入新的用户及其存款金额
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
        
        // 如果是更新成功并且有新的用户排名，调整顺序
        if (isUpdated) {
            sortTopUsers();
        }
    }
    
    // 排序前3名用户（降序排列）
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

    // 提现方法，只有管理员可以调用
    function withdraw() external {
        // 只允许管理员提取资金
        if (msg.sender != admin) {
            return;
        }

        // 一次性提取全部资金
        payable(admin).transfer(address(this).balance);
    }

    // // 查看合约的余额
    // function contractBalance() external view returns (uint256) {
    //     return address(this).balance;
    // }

    // // 查看某个用户的存款金额
    // function checkDeposit(address user) external view returns (uint256) {
    //     return deposits[user];
    // }

    // 获取前3名存款用户及其金额
    function getTopUsers() external view returns (address[] memory, uint256[] memory) {
        return (topUsers, topDeposits);
    }
}
