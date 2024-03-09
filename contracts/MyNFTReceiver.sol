// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MyNFTReceiver is IERC721Receiver {
    event Received(address operator, address from, uint256 tokenId, bytes data);

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
        public
        override
        returns (bytes4)
    {
        // 处理收到 ERC721 代币的逻辑
        emit Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
}
