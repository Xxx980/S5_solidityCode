// test/TokenBankTest.t.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/mytoken_permit.sol"; // 假设 MyToken 支持 Permit
import "../src/tokenBank_permit.sol"; // TokenBank 合约

contract TokenBankTest is Test {
    MyToken myToken;    // ERC20 代币合约实例
    TokenBank tokenBank; // TokenBank 合约实例
    address owner;      // 部署者地址
    address user1;      // 测试用户地址
    uint256 ownerPrivateKey = 0x123; // 示例私钥，用于签名
    uint256 user1PrivateKey = 0x345; // 示例私钥，用于签名

    // 初始化测试环境
    function setUp() public {
        // 设置测试账户
        owner = vm.addr(ownerPrivateKey);
        user1 = vm.addr(user1PrivateKey);

        // 部署 MyToken 合约
        vm.startPrank(owner);
        myToken = new MyToken();
        vm.stopPrank();

        // 部署 TokenBank 合约
        vm.startPrank(owner);
        tokenBank = new TokenBank(myToken);
        vm.stopPrank();

        // 给 user1 铸造 1000 ether 的代币
        vm.prank(owner);
        myToken.mint(user1, 1000 ether);
    }

    // 测试普通存款功能
    function testDeposit() public {
        uint256 depositAmount = 100 ether;

        // user1 授权 TokenBank 转移代币
        vm.prank(user1);
        myToken.approve(address(tokenBank), depositAmount);

        // user1 调用 deposit 存款
        vm.prank(user1);
        tokenBank.deposit(depositAmount);

        // 验证结果
        assertEq(tokenBank.deposits(user1), depositAmount, "Deposit balance is incorrect");
        assertEq(myToken.balanceOf(user1), 900 ether, "User's token balance is incorrect");
        assertEq(myToken.balanceOf(address(tokenBank)), depositAmount, "TokenBank's token balance is incorrect");
    }

    // 测试通过 Permit 存款功能
    function testPermitDeposit() public {
        uint256 depositAmount = 100 ether;
        uint256 deadline = block.timestamp + 1 days;

        // 获取当前 nonce
        uint256 nonce = myToken.nonces(user1);

        // 创建 Permit 结构哈希
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(tokenBank),
                depositAmount,
                nonce,
                deadline
            )
        );

        // 获取 DOMAIN_SEPARATOR
        bytes32 domainSeparator = myToken.DOMAIN_SEPARATOR();

        // 计算签名用的 digest
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        // 使用私钥签名 (这里假设 owner 是签名者，仅为示例)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, digest);

        // user1 调用 permitDeposit
        vm.prank(user1);
        tokenBank.permitDeposit(depositAmount, deadline, v, r, s);

        // 验证结果
        assertEq(tokenBank.deposits(user1), depositAmount, "Deposit balance is incorrect");
        assertEq(myToken.balanceOf(user1), 900 ether, "User's token balance is incorrect");
        assertEq(myToken.balanceOf(address(tokenBank)), depositAmount, "TokenBank's token balance is incorrect");
    }

    // 测试提款功能
    function testWithdraw() public {
        uint256 depositAmount = 100 ether;
        uint256 withdrawAmount = 50 ether;

        // 先存款
        vm.prank(user1);
        myToken.approve(address(tokenBank), depositAmount);
        vm.prank(user1);
        tokenBank.deposit(depositAmount);

        // 调用 withdraw 提款
        vm.prank(user1);
        tokenBank.withdraw(withdrawAmount);

        // 验证结果
        assertEq(tokenBank.deposits(user1), depositAmount - withdrawAmount, "Deposit balance is incorrect");
        assertEq(myToken.balanceOf(user1), 950 ether, "User's token balance is incorrect");
        assertEq(myToken.balanceOf(address(tokenBank)), depositAmount - withdrawAmount, "TokenBank's token balance is incorrect");
    }

    // 测试查询余额功能
    function testBalanceOf() public {
        uint256 depositAmount = 100 ether;

        // 先存款
        vm.prank(user1);
        myToken.approve(address(tokenBank), depositAmount);
        vm.prank(user1);
        tokenBank.deposit(depositAmount);

        // 查询余额并验证
        uint256 balance = tokenBank.balanceOf(user1);
        assertEq(balance, depositAmount, "Balance query is incorrect");
    }
}