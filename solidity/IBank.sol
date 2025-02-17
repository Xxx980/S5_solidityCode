// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBank {
    // function deposit() external payable; // 存款
    function withdraw() external; // 提现
    function getTopUsers() external view returns (address[] memory, uint256[] memory); // 获取前3用户
}
