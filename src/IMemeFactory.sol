// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMemeFactory {
    // 事件
    event MemeDeployed(address indexed token, address indexed creator, string symbol, uint256 totalSupply, uint256 perMint, uint256 price);
    event MemeMinted(address indexed token, address indexed buyer, uint256 amount, uint256 cost);
    
    // 常量
    function PROJECT_FEE_PERCENTAGE() external view returns (uint256);
    function FEE_DENOMINATOR() external view returns (uint256);
    
    // 状态变量
    function memeTokenImplementation() external view returns (address);
    function owner() external view returns (address);
    
    // 主要方法
    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address);
    
    function mintMeme(address tokenAddr) external payable;
    
    // 管理方法
    function emergencyWithdraw() external;
} 