// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/nftmarket.sol";  // 假设你的 NFTMarket 合约在 src 目录下
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



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


contract NFTMarketTest2 is Test {
    NFTMarket public nftMarket;
    MockERC20 public paymentToken;
    MockERC721 public nftToken;
    address public owner;
    address public buyer;
    uint256 public tokenId;

    function setUp() public {
        owner = makeAddr("owner"); 
        buyer = makeAddr("buyer");

        paymentToken = new MockERC20();
        nftToken = new MockERC721();
        
        nftMarket = new NFTMarket(address(paymentToken), address(nftToken));

        tokenId = 1;
        nftToken.mint(owner, tokenId);

        // 隨機分配代幣給 buyer，範圍在 1 到 1000 MTK 之間
        uint256 randomAmount = bound(uint256(keccak256(abi.encodePacked(block.timestamp, buyer))), 1 * 10 ** 18, 1000 * 10 ** 18);
        paymentToken.transfer(buyer, randomAmount);
    }

    // 測試 NFT 掛單功能，隨機價格
    function testListNFT(uint256 price) public {
        price = bound(price, 1 * 10 ** 18, 1000 * 10 ** 18);

        vm.prank(owner);
        nftMarket.list(tokenId, price);

        uint256 listedPrice = nftMarket.nftPrices(tokenId);
        address nftOwner = nftMarket.nftOwners(tokenId);

        assertEq(listedPrice, price);
        assertEq(nftOwner, owner);
    }

    // 測試 NFT 購買功能，隨機價格
    function testBuyNFT(uint256 price) public {
        uint256 buyerBalance = paymentToken.balanceOf(buyer);
        vm.assume(buyerBalance > 0);
        price = bound(price, 1 * 10 ** 18, buyerBalance);

        uint256 buyerBalanceBefore = paymentToken.balanceOf(buyer);
        uint256 ownerBalanceBefore = paymentToken.balanceOf(owner);

        vm.prank(owner);
        nftMarket.list(tokenId, price);

        vm.startPrank(buyer);
        paymentToken.approve(address(nftMarket), price);
        nftMarket.buyNFT(tokenId);
        vm.stopPrank();

        assertEq(paymentToken.balanceOf(buyer), buyerBalanceBefore - price);
        assertEq(paymentToken.balanceOf(owner), ownerBalanceBefore + price);
        assertEq(nftToken.ownerOf(tokenId), buyer);
    }

    // 測試阻止購買自己的 NFT，隨機價格
    function test_RevertWhen_BuyingOwnNFT(uint256 price) public {
        price = bound(price, 1 * 10 ** 18, 1000 * 10 ** 18);

        vm.prank(owner);
        nftMarket.list(tokenId, price);

        vm.startPrank(owner);
        paymentToken.approve(address(nftMarket), price);
        vm.expectRevert("You cannot buy your own NFT");
        nftMarket.buyNFT(tokenId);
        vm.stopPrank();
    }

    // 測試阻止購買未掛單的 NFT
    function test_RevertWhen_BuyingUnlistedNFT(uint256 price) public {
        price = bound(price, 1 * 10 ** 18, 1000 * 10 ** 18);

        vm.prank(buyer);
        paymentToken.approve(address(nftMarket), price);
        vm.expectRevert("NFT is not listed for sale");
        nftMarket.buyNFT(tokenId);
    }
}