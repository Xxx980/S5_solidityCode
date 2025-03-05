pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is ERC20 {
    constructor() ERC20("MKM", "MKM") {

        _mint(msg.sender, 100000 * 10000 ** 18);
    }
    
}

