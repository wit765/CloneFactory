// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MemeToken.sol";

contract MemeFactory is Ownable {
    MemeToken public immutable memeTokenImplementation;
    
    // 项目方费用比例 (1% = 100)
    uint256 public constant PROJECT_FEE_PERCENTAGE = 100; // 1%
    uint256 public constant FEE_DENOMINATOR = 10000; // 100%
    
    // 事件
    event MemeDeployed(address indexed token, address indexed creator, string symbol, uint256 totalSupply, uint256 perMint, uint256 price);
    event MemeMinted(address indexed token, address indexed buyer, uint256 amount, uint256 cost);
    
    constructor(address initialOwner) Ownable(initialOwner) {
        // 部署实现合约
        memeTokenImplementation = new MemeToken();
    }
    
    function deployMeme(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address) {
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(perMint > 0, "Per mint must be greater than 0");
        require(perMint <= totalSupply, "Per mint cannot exceed total supply");
        require(price > 0, "Price must be greater than 0");
        
        // 使用最小代理模式部署
        address memeToken = Clones.clone(address(memeTokenImplementation));
        
        // 初始化代理合约
        MemeToken(memeToken).initialize(
            symbol,
            totalSupply,
            perMint,
            price,
            msg.sender // 发行者作为owner
        );
        
        emit MemeDeployed(memeToken, msg.sender, symbol, totalSupply, perMint, price);
        
        return memeToken;
    }
    
    function mintMeme(address tokenAddr) external payable {
        MemeToken token = MemeToken(tokenAddr);
        
        // 获取代币信息
        (uint256 totalSupplyLimit, uint256 perMint, uint256 price) = token.getMintInfo();
        
        // 检查是否还有代币可以铸造
        require(token.totalSupply() + perMint <= totalSupplyLimit, "Exceeds total supply limit");
        
        // 检查支付金额
        require(msg.value >= price, "Insufficient payment");
        
        // 计算费用分配
        uint256 projectFee = (price * PROJECT_FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 creatorFee = price - projectFee;
        
        // 铸造代币给购买者
        token.mintFromFactory(msg.sender, perMint, address(this));
        
        // 分配费用
        address creator = token.owner();
        
        if (projectFee > 0) {
            (bool projectFeeSuccess, ) = owner().call{value: projectFee}("");
            require(projectFeeSuccess, "Project fee transfer failed");
        }
        
        if (creatorFee > 0) {
            (bool creatorFeeSuccess, ) = creator.call{value: creatorFee}("");
            require(creatorFeeSuccess, "Creator fee transfer failed");
        }
        
        // 退还多余的ETH
        uint256 excess = msg.value - price;
        if (excess > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: excess}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit MemeMinted(tokenAddr, msg.sender, perMint, price);
    }
    
    // 紧急提取函数（仅owner可调用）
    function emergencyWithdraw() external onlyOwner {
        address payable ownerAddress = payable(owner());
        (bool success, ) = ownerAddress.call{value: address(this).balance}("");
        require(success, "Emergency withdraw failed");
    }
} 