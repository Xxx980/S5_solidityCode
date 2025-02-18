// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenBank.sol";  // 导入 TokenBank 合约
import "./ExtendedERC20.sol";  // 导入 ExtendedERC20 合约

contract TokenBankV2 is TokenBank, ITokenReceiver {

    constructor(ExtendedERC20 _token) TokenBank(_token) {}

    // 实现 tokensReceived 方法，处理存款记录工作
    function tokensReceived(address /* operator */, address from, uint256 amount) external override {
        require(address(token) == msg.sender, "TokenBankV2: invalid token");
        // 如果是从合约调用的 token transferWithCallback，将存款记录
        deposits[from] += amount;
        emit Deposited(from, amount);
    }

    // 重写 balanceOf 方法，查询存款
    function balanceOf(address account) public view override returns (uint256) {
        return deposits[account];
    }
}
