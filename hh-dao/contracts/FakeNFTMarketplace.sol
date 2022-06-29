// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.10;

contract FakeNFTMarketplace {
    // Mapping for fake tokenId to owner address
    mapping(uint256 => address) public tokens;
    // Purchase price for each fake FakeNft
    uint256 nftPrice = 0.1 ether;

    // purchase accepts eth and marks the owner of a tokenId to caller address
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT cost 0.1 ETH");
        tokens[_tokenId] = msg.sender;
    }

    // returns the price of one NFT 
    function getPrice() external view returns (uint256) {
        return nftPrice; 

    }

    // checks where a given nft has been solder or not
    function available(uint256 _tokenId) external view returns (bool) {
        // address(0) = 0x000000000000000000000000
        // default address for solidity 
        if (tokens[_tokenId] == address(0)) {
            return true;
    }
    return false;
    }
}