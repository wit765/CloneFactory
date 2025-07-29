// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMemeToken {
    // 状态变量
    function totalSupplyLimit() external view returns (uint256);
    function perMint() external view returns (uint256);
    function price() external view returns (uint256);
    function initialized() external view returns (bool);
    function owner() external view returns (address);
    
    // ERC20 标准方法
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    // 自定义方法
    function initialize(
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint,
        uint256 _price,
        address initialOwner
    ) external;
    
    function mint(address to, uint256 amount) external;
    function getMintInfo() external view returns (uint256, uint256, uint256);
} 