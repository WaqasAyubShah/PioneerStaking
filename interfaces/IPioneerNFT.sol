// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.9;

/// @dev an interface to interact with the Genesis Verse NFT that will 
interface IPioneerNFT {
    function primarySalePrice(uint256 tokenId) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}