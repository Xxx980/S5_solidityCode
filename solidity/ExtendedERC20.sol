// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseErc20.sol";  // 假设 BaseERC20 合约在相同目录下

// 定义 ITokenReceiver 接口
interface ITokenReceiver {
    function tokensReceived(address operator, address from, uint256 amount) external;
}

contract ExtendedERC20 is BaseERC20 {
    

    // 具有 callback 功能的转账函数
    function transferWithCallback(address _to, uint256 _value) public returns (bool success) {
        // 转账之前的基础检查
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

        // 转账操作
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // 如果目标地址是合约地址，并且该合约实现了 tokensReceived 函数
        if (isContract(_to)) {
            ITokenReceiver(_to).tokensReceived(msg.sender, msg.sender, _value);
        }

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // 判断目标地址是否为合约地址
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
