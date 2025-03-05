// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./mytoken_permit.sol";  // 假设 MyToken 继承 ERC20 并支持 permit
// import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

contract TokenBank {
    MyToken public token;  // 记录与 TokenBank 交互的 ERC20 代币合约

    mapping(address => uint256) public deposits;  // 记录每个地址存入的代币数量

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(MyToken _token) {
        token = _token;  // 设置与 TokenBank 交互的 Token 合约
    }

    // 存款方法，用户调用该方法将代币存入 TokenBank
    function deposit(uint256 amount) public {
        require(amount > 0, "Deposit amount must be greater than zero");

        // 用户调用 transferFrom 将代币转到 TokenBank 合约地址
        require(token.transferFrom(msg.sender, address(this), amount), "ERC20: transfer failed");

        // 更新用户的存款余额
        deposits[msg.sender] += amount;

        emit Deposited(msg.sender, amount);
    }

    // 通过 permit 授权并存款
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(amount > 0, "Deposit amount must be greater than zero");

        // 先执行 permit 授权
        IERC20Permit(address(token)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        // 调用 transferFrom 进行存款
        require(token.transferFrom(msg.sender, address(this), amount), "ERC20: transfer failed");

        // 更新存款余额
        deposits[msg.sender] += amount;

        emit Deposited(msg.sender, amount);
    }

    // 提款方法，允许用户从 TokenBank 提取代币
    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(deposits[msg.sender] >= amount, "Insufficient balance");

        // 更新用户的存款余额
        deposits[msg.sender] -= amount;

        // 用户调用 transfer 将代币从 TokenBank 合约地址转回用户
        require(token.transfer(msg.sender, amount), "ERC20: transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // 查询某个地址在 TokenBank 中的存款数量
    function balanceOf(address account) public view returns (uint256) {
        return deposits[account];
    }
}
