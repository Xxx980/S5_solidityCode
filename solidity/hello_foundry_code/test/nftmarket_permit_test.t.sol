// test/NFTMarketTest.t.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/mytoken_permit.sol";
import "../src/MyNFT.sol";
import "../src/nft_market_permit.sol";

contract NFTMarketTest1 is Test {
    MyToken myToken;
    MyNFT myNFT;
    NFTMarket market;

    // 定义测试账户及其私钥
    uint256 ownerPrivateKey = 1;
    address owner = vm.addr(ownerPrivateKey);
    uint256 sellerPrivateKey = 2;
    address seller = vm.addr(sellerPrivateKey);
    uint256 buyerPrivateKey = 3;
    address buyer = vm.addr(buyerPrivateKey);

    function setUp() public {
        // 部署合约
        vm.startPrank(owner);
        myToken = new MyToken();
        myNFT = new MyNFT();
        market = new NFTMarket(address(myToken), address(myNFT));
        vm.stopPrank();

        // 给卖家铸造 NFT
        vm.prank(owner);
        myNFT.mint(seller, 1);

        // 给买家铸造代币
        vm.prank(owner);
        myToken.mint(buyer, 1000 ether);
    }

    function testListNFT() public {
        uint256 tokenId = 1;
        uint256 price = 50 ether;

        // 卖家授权市场合约转移 NFT
        vm.prank(seller);
        myNFT.approve(address(market), tokenId);

        // 卖家列出 NFT
        vm.prank(seller);
        market.list(tokenId, price);

        // 验证结果
        assertEq(myNFT.ownerOf(tokenId), seller, "NFT should still be owned by seller");
        assertEq(market.nftPrices(tokenId), price, "NFT price is incorrect");

        console.log("After seller lists NFT:");
        console.log("- NFT ", tokenId, " owner: ", myNFT.ownerOf(tokenId));
        console.log("- NFT price: ", market.nftPrices(tokenId) / 1e18);
    }

    function testBuyNFT() public {
        uint256 tokenId = 1;
        uint256 price = 50 ether;

        // 卖家列出 NFT
        vm.startPrank(seller);
        myNFT.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();

        // 买家授权市场合约花费代币
        vm.prank(buyer);
        myToken.approve(address(market), price);

        // 记录初始状态
        uint256 initialSellerBalance = myToken.balanceOf(seller);
        uint256 initialBuyerBalance = myToken.balanceOf(buyer);

        // 买家购买 NFT
        vm.prank(buyer);
        market.buyNFT(tokenId);

        // 验证结果
        assertEq(myNFT.ownerOf(tokenId), buyer, "NFT not transferred to buyer");
        assertEq(myToken.balanceOf(seller), initialSellerBalance + price, "Seller did not receive payment");
        assertEq(myToken.balanceOf(buyer), initialBuyerBalance - price, "Buyer's balance not reduced");
        assertEq(market.nftPrices(tokenId), 0, "NFT price not reset");

        console.log("After buyer buys NFT:");
        console.log("- NFT ", tokenId, " owner: ", myNFT.ownerOf(tokenId));
        console.log("- Seller's token balance: ", myToken.balanceOf(seller) / 1e18);
        console.log("- Buyer's token balance: ", myToken.balanceOf(buyer) / 1e18);
    }
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
    function testPermitBuy() public {
        uint256 tokenId = 1;
        uint256 price = 50 ether;
        uint256 deadline = block.timestamp + 1 hours;

        // 卖家列出 NFT
        vm.startPrank(seller);
        myNFT.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();
    
        // 生成 permitBuy 的签名
        bytes32 messageHash = keccak256(abi.encodePacked(buyer, tokenId, price, deadline));
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 买家授权市场合约花费代币
        vm.prank(buyer);
        myToken.approve(address(market), price);

        // 记录初始状态
        uint256 initialSellerBalance = myToken.balanceOf(seller);
        uint256 initialBuyerBalance = myToken.balanceOf(buyer);

        // 买家调用 permitBuy
        vm.prank(buyer);
        market.permitBuy(tokenId, price, deadline, signature);

        // 验证结果
        assertEq(myNFT.ownerOf(tokenId), buyer, "NFT not transferred to buyer");
        assertEq(myToken.balanceOf(seller), initialSellerBalance + price, "Seller did not receive payment");
        assertEq(myToken.balanceOf(buyer), initialBuyerBalance - price, "Buyer's balance not reduced");
        assertEq(market.nftPrices(tokenId), 0, "NFT price not reset");

        console.log("After buyer permitBuy NFT:");
        // console.log("- NFT ", tokenId, " owner: ", myNFT.ownerOf(tokenId));
        console.log("- Seller's token balance: ", myToken.balanceOf(seller) / 1e18);
        console.log("- Buyer's token balance: ", myToken.balanceOf(buyer) / 1e18);
    }
}