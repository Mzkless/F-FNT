// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {MyNFT} from "./MyNFT.sol";
import {MyNFTReceiver} from "./MyNFTReceiver.sol";

contract NFTExchange is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => uint256) private _listingPrices;
    mapping(uint256 => address) private _nftOwners;

    MyNFT private myNFT;

    constructor(address myNFTAddress) ERC721("NFTExchange", "NFTX") {
        myNFT = MyNFT(myNFTAddress);
    }

    function uploadNFT(uint256 tokenId, uint256 listingPrice)
        external
        returns (uint256)
    {
        //上架到交易所
        // Verify if the sender owns the NFT
        require(myNFT.ownerOf(tokenId) == msg.sender, "You don't own this NFT");

        // Verify if the sender has approved the NFT for transfer to this contract
        require(
            myNFT.getApproved(tokenId) == address(this),
            "You haven't approved the NFT for transfer"
        );

        // Transfer the NFT to this contract
        myNFT.transferFrom(msg.sender, address(this), tokenId);

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, myNFT.tokenURI(tokenId));
        _listingPrices[newTokenId] = listingPrice;
        _nftOwners[newTokenId] = msg.sender;
        return newTokenId;
    }

    function buyNFT(uint256 tokenId) external payable returns (bool){
        //在交易所购买NFT
        require(_exists(tokenId), "NFT does not exist");
        require(_listingPrices[tokenId] > 0, "NFT is not listed for sale");
        require(msg.value == _listingPrices[tokenId], "Insufficient payment");
        address payable seller = payable(_nftOwners[tokenId]);
        address buyer = msg.sender;
        // uint256 purchasePrice = _listingPrices[tokenId];

        _transfer(seller, buyer, tokenId);
        /*(bool success, ) = buyer.call{value: _listingPrices[tokenId]}("");
        require(success, "Failed to transact");*/
        seller.transfer(_listingPrices[tokenId]);
        _listingPrices[tokenId] = 0;
        _nftOwners[tokenId] = buyer;
        return true;
    }

    function AfterVotingbuyNFT(uint256 tokenId,address succeedProposer) external payable returns (bool){  //内置函数，不需要用户调用
        //在交易所购买NFT
        require(_exists(tokenId), "NFT does not exist");
        require(_listingPrices[tokenId] > 0, "NFT is not listed for sale");
        //require(msg.value+i == _listingPrices[tokenId], "Insufficient payment");
        address payable seller = payable(_nftOwners[tokenId]);
        address buyer = succeedProposer;
        // uint256 purchasePrice = _listingPrices[tokenId];

        _transfer(seller, buyer, tokenId);
        /*(bool success, ) = buyer.call{value: _listingPrices[tokenId]}("");
        require(success, "Failed to transact");*/
        seller.transfer(_listingPrices[tokenId]);
        _listingPrices[tokenId] = 0;
        _nftOwners[tokenId] = buyer;
        return true;
        // if (msg.value > purchasePrice) {
        //     // Refund excess payment
        //     (bool success, ) = buyer.call{value: msg.value - purchasePrice}("");
        //     require(success, "Failed to refund excess payment");
        // }
    }

    function withdrawNFT(uint256 tokenId, address to) external {
        //
        require(
            ownerOf(tokenId) == address(this),
            "NFT is not held by the contract"
        );

        // Transfer the NFT to the specified address
        safeTransferFrom(address(this), to, tokenId);
    }

    function setListingPrice(uint256 tokenId, uint256 listingPrice) external {
        require(_exists(tokenId), "NFT does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner can set the listing price"
        );

        _listingPrices[tokenId] = listingPrice;
    }

    function removeListing(uint256 tokenId) external {
        require(_exists(tokenId), "NFT does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner can remove the listing"
        );

        _listingPrices[tokenId] = 0;
    }

    function getListingPrice(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");

        return _listingPrices[tokenId];
    }

    function getNFTOwner(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "NFT does not exist");

        return _nftOwners[tokenId];
    }
}
