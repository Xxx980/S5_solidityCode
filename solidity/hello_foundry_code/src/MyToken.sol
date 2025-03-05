// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyTokenOZ is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("MyTokenOZ", "MTOZ") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10**decimals()); // 初始供应量，考虑小数位
    }

    // 可选：添加 mint 功能，仅限 owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // 可选：添加 burn 功能，任何持有者都可以销毁自己的代币
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}