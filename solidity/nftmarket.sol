// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is Ownable {
    // Mapping to track the price of listed NFTs
    mapping(uint256 => uint256) public nftPrices;  // nftTokenId => price in MyToken
    mapping(uint256 => address) public nftOwners;   // nftTokenId => current owner
    IERC20 public paymentToken;  // The ERC20 token used for purchasing NFTs
    IERC721 public nftToken;  // The ERC721 token used for purchasing NFTs

    // Constructor with the payment token and nft token address
    constructor(address _paymentToken, address _nftToken) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentToken);
        nftToken = IERC721(_nftToken);
    }

    // Event for listing an NFT
    event NFTListed(uint256 indexed tokenId, uint256 price, address indexed owner);
    // Event for purchase of an NFT
    event NFTPurchased(uint256 indexed tokenId, uint256 price, address indexed buyer);

    // List an NFT for sale, owner can specify the price in MyToken
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        address owner = msg.sender;
        
        // Ensure the sender is the owner of the NFT
        require(nftToken.ownerOf(tokenId) == owner, "You must own the NFT");

        // Optionally transfer the NFT to the contract (if you want the market to hold it)
        // nftToken.transferFrom(owner, address(this), tokenId);

        // Set the price for the listed NFT
        nftPrices[tokenId] = price;
        nftOwners[tokenId] = owner;

        emit NFTListed(tokenId, price, owner);
    }

    // Buy an NFT by paying the specified price in ERC20 tokens
    function buyNFT(uint256 tokenId) external {
        uint256 price = nftPrices[tokenId];
        address seller = nftOwners[tokenId];
        
        require(price > 0, "NFT is not listed for sale");
        require(seller != msg.sender, "You cannot buy your own NFT");

        // Transfer the ERC20 token from buyer to seller
        require(paymentToken.transferFrom(msg.sender, seller, price), "Payment failed");

        // Transfer the NFT from seller to buyer
        nftToken.safeTransferFrom(seller, msg.sender, tokenId);

        // Reset the listing information
        delete nftPrices[tokenId];
        delete nftOwners[tokenId];

        emit NFTPurchased(tokenId, price, msg.sender);
    }
}
