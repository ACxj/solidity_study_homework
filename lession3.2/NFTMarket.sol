// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTMarket {
    struct NFT {
        uint256 id;
        address owner;
        uint256 price;
        bool forSale;
    }

    mapping(uint256 => NFT) private nfts;
    uint256 private nextId;
    uint256[] private forSaleList;

    error NFTNotFound(uint256 id);
    error NotOwner();
    error PriceMustBePositive();
    error NotForSale(uint256 id);
    error InsufficientPayment(uint256 required, uint256 sent);
    error TransferFailed();

    event NFTMinted(uint256 indexed id, address indexed owner);
    event ListedForSale(uint256 indexed id, uint256 price);
    event RemovedFromSale(uint256 indexed id);
    event NFTSold(uint256 indexed id, address indexed buyer, uint256 price);

    function mintNFT() external returns (uint256) {
        uint256 id = nextId++;
        nfts[id] = NFT({
            id: id,
            owner: msg.sender,
            price: 0,
            forSale: false
        });

        emit NFTMinted(id, msg.sender);
        return id;
    }

    function listForSale(uint256 id, uint256 price) external {
        if (price == 0) revert PriceMustBePositive();
        if (nfts[id].owner != msg.sender) revert NotOwner();
        if (nfts[id].forSale) revert NotForSale(id);

        nfts[id].price = price;
        nfts[id].forSale = true;
        forSaleList.push(id);

        emit ListedForSale(id, price);
    }

    function removeFromSale(uint256 id) external {
        if (nfts[id].owner != msg.sender) revert NotOwner();
        if (!nfts[id].forSale) revert NotForSale(id);

        nfts[id].forSale = false;
        nfts[id].price = 0;

        uint256 len = forSaleList.length;
        for (uint256 i = 0; i < len; ++i) {
            if (forSaleList[i] == id) {
                forSaleList[i] = forSaleList[len - 1];
                forSaleList.pop();
                break;
            }
        }

        emit RemovedFromSale(id);
    }

    function buyNFT(uint256 id) external payable {
        if (nfts[id].owner == address(0)) revert NFTNotFound(id);
        if (!nfts[id].forSale) revert NotForSale(id);
        if (msg.value < nfts[id].price) revert InsufficientPayment(nfts[id].price, msg.value);

        address seller = nfts[id].owner;
        uint256 price = nfts[id].price;

        nfts[id].owner = msg.sender;
        nfts[id].forSale = false;
        nfts[id].price = 0;

        uint256 len = forSaleList.length;
        for (uint256 i = 0; i < len; ++i) {
            if (forSaleList[i] == id) {
                forSaleList[i] = forSaleList[len - 1];
                forSaleList.pop();
                break;
            }
        }

        (bool success, ) = seller.call{value: price}("");
        if (!success) revert TransferFailed();

        emit NFTSold(id, msg.sender, price);
    }

    function getNFT(uint256 id) external view returns (NFT memory) {
        if (nfts[id].owner == address(0)) revert NFTNotFound(id);
        return nfts[id];
    }

    function getNFTsForSale() external view returns (NFT[] memory result) {
        uint256 count = forSaleList.length;
        result = new NFT[](count);

        for (uint256 i = 0; i < count; ++i) {
            result[i] = nfts[forSaleList[i]];
        }
    }

    function getNFTCount() external view returns (uint256 total, uint256 forSale) {
        return (nextId, forSaleList.length);
    }
}