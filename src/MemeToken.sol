// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeToken is ERC20, Ownable {
    uint256 public totalSupplyLimit;
    uint256 public perMint;
    uint256 public price;
    bool public initialized;
    string public customSymbol;
    
    constructor() ERC20("Meme Token", "MEME") Ownable(msg.sender) {
        // 使用msg.sender作为初始owner，在initialize中会被重新设置
    }
    
    function initialize(
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _perMint,
        uint256 _price,
        address initialOwner
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;
        
        // 设置owner
        _transferOwnership(initialOwner);
        
        // 设置参数
        totalSupplyLimit = _totalSupply;
        perMint = _perMint;
        price = _price;
        customSymbol = _symbol;
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= totalSupplyLimit, "Exceeds total supply limit");
        _mint(to, amount);
    }
    
    // 允许工厂合约代表owner铸造
    function mintFromFactory(address to, uint256 amount, address factory) external {
        require(msg.sender == factory, "Only factory can call this");
        require(totalSupply() + amount <= totalSupplyLimit, "Exceeds total supply limit");
        _mint(to, amount);
    }
    
    function getMintInfo() external view returns (uint256, uint256, uint256) {
        return (totalSupplyLimit, perMint, price);
    }
} 