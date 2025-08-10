// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../IUniswapV2Factory.sol";

contract MockUniswapV2Factory is IUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    mapping(address => mapping(address => bool)) public pairExists;

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(!pairExists[tokenA][tokenB] && !pairExists[tokenB][tokenA], "PAIR_EXISTS");
        // 模拟配对地址（例如，一个虚拟地址）
        pair = address(uint160(uint256(keccak256(abi.encodePacked(tokenA, tokenB)))));
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        pairExists[tokenA][tokenB] = true;
        pairExists[tokenB][tokenA] = true;
    }
}
