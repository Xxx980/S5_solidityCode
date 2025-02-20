// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/nftmarket.sol";  // 假设你的 NFTMarket 合约在 src 目录下
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 创建一个虚拟的 ERC20 和 ERC721 合约用于测试
contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 100000 * 10000 ** 18);  // 给部署者分配 100 个代币
    }
}

contract MockERC721 is IERC721 {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _owners[tokenId];
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function approve(address to, uint256 tokenId) public override {
        _tokenApprovals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_owners[tokenId] == from, "ERC721: transfer from incorrect owner");
        _owners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] += 1;
    }

    // Implementing safeTransferFrom
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory /* data */) public override {
    transferFrom(from, to, tokenId);
}


    // Implementing supportsInterface (ERC165)
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    // Mint function to create a new token (for testing)
    function mint(address to, uint256 tokenId) public {
        require(_owners[tokenId] == address(0), "ERC721: token already minted");
        _owners[tokenId] = to;
        _balances[to] += 1;
    }
}



contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    MockERC20 public paymentToken;
    MockERC721 public nftToken;
    address public owner;
    address public buyer;
    uint256 public tokenId;

    function setUp() public {
        owner = makeAddr("owner"); 
        buyer = makeAddr("buyer");

        // 部署 MockERC20 和 MockERC721 合约
        paymentToken = new MockERC20();
        nftToken = new MockERC721();
        
        // 部署 NFTMarket 合约并将 MockERC20 地址传递给它
        nftMarket = new NFTMarket(address(paymentToken), address(nftToken));


        // mint 一个 ERC721 token 给 owner
        tokenId = 1;
        nftToken.mint(owner, tokenId);

        // 为 buyer 地址分配 ERC20 代币
        paymentToken.transfer(buyer, 100000 * 10000 ** 18);  // 给 buyer 转账 100 个代币
    }

    function testListNFT(uint256 price) public {
        
        // uint256 price = price


        uint256 maxPrice = 1000 * 10 ** 18;  // 假设最大价格为 1000 MTK
        vm.assume(price > 0 && price <= maxPrice);
        // require(condition);

        // Owner 列出 NFT
        vm.prank(owner);  // 模拟 Owner 地址
        nftMarket.list(tokenId, price);

        // 检查 NFT 是否成功列出
        uint256 listedPrice = nftMarket.nftPrices(tokenId);
        address nftOwner = nftMarket.nftOwners(tokenId);

        assertEq(listedPrice, price);
        assertEq(nftOwner, owner);
    }

    function testBuyNFT(uint256 price) public {
    uint256 buyerBalanceBefore = paymentToken.balanceOf(buyer);
    uint256 ownerBalanceBefore = paymentToken.balanceOf(owner);

    uint256 maxPrice = 1000 * 10 ** 18;  // 假设最大价格为 1000 MTK
    vm.assume(price > 0 && price <= maxPrice);
    //  = 10 * 10 ** 18; 
     // 10 MTK

    // Owner 列出 NFT
    vm.prank(owner);  // 模拟 Owner 地址
    nftMarket.list(tokenId, price);

    // Buyer 执行购买
    vm.startPrank(buyer);  // 模拟 Buyer 地址
    
    // 确保 Buyer 授权 nftMarket 足够的代币
    paymentToken.approve(address(nftMarket), price);  // 允许 nftMarket 转移代币

    // 执行购买
    nftMarket.buyNFT(tokenId);
    

    // 检查购买后的余额和所有权
    assertEq(paymentToken.balanceOf(buyer), buyerBalanceBefore - price);  // Buyer 应该支付了价格
    assertEq(paymentToken.balanceOf(owner), ownerBalanceBefore + price);  // 应该收到代币
    
    assertEq(nftToken.ownerOf(tokenId), buyer);  // NFT 应该转移给 Buyer
}


    function test_RevertWhen_BuyingOwnNFT() public {
    uint256 price = 10 * 10 ** 18;  // 10 MTK

    // Owner 列出 NFT
    vm.prank(owner);  // 模拟 Owner 地址
    nftMarket.list(tokenId, price);

    // Owner 尝试购买自己列出的 NFT（应该失败）
    vm.prank(owner);  // 模拟 Owner 地址
    paymentToken.approve(address(nftMarket), uint256(price));
    vm.expectRevert("You cannot buy your own NFT");  // 预期错误
    // vm.startPrank(owner);
    vm.prank(owner);
    nftMarket.buyNFT(tokenId);  // 执行购买
}


    function test_RevertWhen_BuyingUnlistedNFT() public {
        uint256 price = 10 * 10 ** 18;  // 10 MTK

        // Buyer 尝试购买未列出的 NFT（应该失败）
        vm.prank(buyer);  // 模拟 Buyer 地址
        paymentToken.approve(address(nftMarket), price);
        vm.expectRevert("NFT is not listed for sale");
        nftMarket.buyNFT(tokenId);
    }
}  