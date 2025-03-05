// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarket is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // 跟踪已列出 NFT 的价格
    mapping(uint256 => uint256) public nftPrices;  // nftTokenId => price in MyToken
    IERC20 public paymentToken;  // 用于购买 NFT 的 ERC20 代币
    IERC721 public nftToken;     // 用于购买的 ERC721 NFT 代币
    // address public owner;
    // address public whitelistSigner; // 白名单签名者的地址
    
    // 构造函数，初始化支付代币、NFT 代币和白名单签名者地址
    constructor(address _paymentToken, address _nftToken) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentToken);
        nftToken = IERC721(_nftToken);
        // owner = msg.sender;
        // whitelistSigner = _whitelistSigner;
    }

    // NFT 列出事件
    event NFTListed(uint256 indexed tokenId, uint256 price, address indexed owner);
    // NFT 购买事件
    event NFTPurchased(uint256 indexed tokenId, uint256 price, address indexed buyer);

    // 列出 NFT 出售，拥有者指定价格（单位为 MyToken）
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        address owner = msg.sender;
        
        // 确保调用者是 NFT 的拥有者
        require(nftToken.ownerOf(tokenId) == owner, "You must own the NFT");
        
        // 确保市场合约已被授权转移 NFT
        require(
            nftToken.getApproved(tokenId) == address(this) || 
            nftToken.isApprovedForAll(owner, address(this)),
            "Market must be approved to transfer NFT"
        );

        // 设置 NFT 的列出价格
        nftPrices[tokenId] = price;

        emit NFTListed(tokenId, price, owner);
    }

    // 通过支付 ERC20 代币购买 NFT
    function buyNFT(uint256 tokenId) external nonReentrant {
        uint256 price = nftPrices[tokenId];
        address seller = nftToken.ownerOf(tokenId); // 从 NFT 合约获取当前拥有者
        
        require(price > 0, "NFT is not listed for sale");
        require(seller != msg.sender, "You cannot buy your own NFT");

        // 从买家转移 ERC20 代币给卖家
        require(paymentToken.transferFrom(msg.sender, seller, price), "Payment failed");

        // 将 NFT 从卖家转移给买家
        nftToken.safeTransferFrom(seller, msg.sender, tokenId);

        // 重置列出信息
        delete nftPrices[tokenId];

        emit NFTPurchased(tokenId, price, msg.sender);
    }

    // 使用白名单许可购买 NFT
    function permitBuy(
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) external nonReentrant {
        require(block.timestamp <= deadline, "Signature expired");
        require(nftPrices[tokenId] == price, "Incorrect price");

        // 创建消息哈希
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, tokenId, price, deadline));
        
        // 转换为以太坊签名消息哈希
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);
        require(signer == owner(),"Invalid signature"
        );

        address seller = nftToken.ownerOf(tokenId); // 从 NFT 合约获取当前拥有者
        require(seller != msg.sender, "You cannot buy your own NFT");

        // 从买家转移 ERC20 代币给卖家
        require(paymentToken.transferFrom(msg.sender, seller, price), "Payment failed");

        // 将 NFT 从卖家转移给买家
        nftToken.safeTransferFrom(seller, msg.sender, tokenId);

        // 重置列出信息
        delete nftPrices[tokenId];

        emit NFTPurchased(tokenId, price, msg.sender);
    }

    // 内部函数，将消息哈希转换为以太坊签名消息哈希
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
}