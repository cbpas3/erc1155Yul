// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract TestReceiver {
    
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address,uint256[] calldata, uint256[] calldata, bytes calldata ) public virtual returns (bytes4){
        return 0xbc197c81;
    }
}