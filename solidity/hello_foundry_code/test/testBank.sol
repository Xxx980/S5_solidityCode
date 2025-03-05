// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/bank.sol";  

contract BankTest is Test {
    Bank bank;
    address user = address(0x123);

    function setUp() public {
        // 部署合约
        bank = new Bank();
    }

    function testDepositETH() public {
        uint depositAmount = 1 ether;

        // 监听 Deposit 事件，断言事件参数
        vm.expectEmit(true, true, true, true); // 只关注事件的地址和数额参数
        emit Bank.Deposit(user, depositAmount);

        // 给 user 地址转账 1 ETH
        vm.deal(user, depositAmount);
        // 执行存款操作
        vm.prank(user); // 确保从正确的地址调用存款方法
        bank.depositETH{value: depositAmount}();

        // 断言存款后余额更新正确
        uint userBalance = bank.balanceOf(user);
        assertEq(userBalance, depositAmount);
    }

    function test_RevertWhen_DepositAmountIsZero() public {
        uint depositAmount = 0;
        vm.prank(user);

        // 调用存款方法时，应该抛出错误
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.depositETH{value: depositAmount}();
    }
}
