// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MemeToken.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract MemeFactory is Ownable {
    MemeToken public immutable memeTokenImplementation;
    
    // 项目方费用比例 (5% = 500)
    uint256 public constant PROJECT_FEE_PERCENTAGE = 500; // 5%
    uint256 public constant FEE_DENOMINATOR = 10000; // 100%
    
    // Uniswap相关
    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Factory public immutable uniswapFactory;
    address public immutable WETH; // WETH地址
    
    // 流动性管理
    mapping(address => bool) public liquidityAdded; // 记录是否已添加流动性
    
    // 事件
    event MemeDeployed(address indexed token, address indexed creator, string symbol, uint256 totalSupply, uint256 perMint, uint256 price);
    event MemeMinted(address indexed token, address indexed buyer, uint256 amount, uint256 cost);
    event LiquidityAdded(address indexed token, uint256 ethAmount, uint256 tokenAmount);
    event MemeBought(address indexed token, address indexed buyer, uint256 amount, uint256 cost);
    
    constructor(address initialOwner, address _uniswapRouter, address _WETH) Ownable(initialOwner) {
        // 部署实现合约
        memeTokenImplementation = new MemeToken();
        
        // 设置Uniswap Router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        WETH = _WETH;
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
            msg.sender, // 发行者作为owner
            address(this) // 工厂地址
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
        
        // 转移项目方费用给项目方
        if (projectFee > 0) {
            (bool projectFeeSuccess, ) = owner().call{value: projectFee}("");
            require(projectFeeSuccess, "Project fee transfer failed");
        }
        
        if (creatorFee > 0) {
            (bool creatorFeeSuccess, ) = creator.call{value: creatorFee}("");
            require(creatorFeeSuccess, "Creator fee transfer failed");
        }
        
        // 暂时跳过流动性添加，直接保留项目方费用
        // 注意：在实际部署中，需要实现完整的流动性管理逻辑
        // _addLiquidityIfNeeded(tokenAddr, projectFee, perMint);
        
        // 退还多余的ETH
        uint256 excess = msg.value - price;
        if (excess > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: excess}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit MemeMinted(tokenAddr, msg.sender, perMint, price);
    }
    
    // 新增：从Uniswap购买Meme代币
    function buyMeme(address tokenAddr, uint256 amount) external payable {
        MemeToken token = MemeToken(tokenAddr);
        
        // 检查代币是否已添加流动性
        require(liquidityAdded[tokenAddr], "Liquidity not added yet");
        
        // 检查支付金额
        require(msg.value > 0, "Must send ETH to buy");
        
        // 计算预期获得的代币数量
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddr;
        
        uint256[] memory amounts = uniswapRouter.getAmountsOut(msg.value, path);
        uint256 expectedTokens = amounts[1];
        
        // 检查是否满足最小数量要求
        require(expectedTokens >= amount, "Insufficient tokens for the amount");
        
        // 执行交换
        uint256[] memory swapAmounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            amount,
            path,
            msg.sender,
            block.timestamp + 300 // 5分钟超时
        );
        
        emit MemeBought(tokenAddr, msg.sender, swapAmounts[1], msg.value);
    }
    
    // 流动性管理函数
    function _addLiquidityIfNeeded(address tokenAddr, uint256 ethAmount, uint256 tokenAmount) private {
        if (!liquidityAdded[tokenAddr]) {
            // 第一次添加流动性
            _addInitialLiquidity(tokenAddr, ethAmount, tokenAmount);
            liquidityAdded[tokenAddr] = true;
        } else {
            // 后续添加流动性
            _addAdditionalLiquidity(tokenAddr, ethAmount, tokenAmount);
        }
    }
    
    // 添加初始流动性
    function _addInitialLiquidity(address tokenAddr, uint256 ethAmount, uint256 tokenAmount) private {
        MemeToken token = MemeToken(tokenAddr);
        
        // 计算需要购买的代币数量（基于价格）
        uint256 tokenPrice = token.price();
        uint256 tokensToBuy = (ethAmount * tokenAmount) / tokenPrice;
        
        // 从代币发行者那里购买代币用于流动性
        address creator = token.owner();
        token.transferFrom(creator, address(this), tokensToBuy);
        
        // 批准Router使用代币
        token.approve(address(uniswapRouter), tokensToBuy);
        
        // 添加流动性
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapRouter.addLiquidityETH{value: ethAmount}(
            tokenAddr,
            tokensToBuy,
            0, // 最小代币数量
            0, // 最小ETH数量
            address(this), // 流动性代币接收者
            block.timestamp + 300 // 5分钟超时
        );
        
        emit LiquidityAdded(tokenAddr, amountETH, amountToken);
    }
    
    // 添加后续流动性
    function _addAdditionalLiquidity(address tokenAddr, uint256 ethAmount, uint256 tokenAmount) private {
        MemeToken token = MemeToken(tokenAddr);
        
        // 计算需要购买的代币数量（基于价格）
        uint256 tokenPrice = token.price();
        uint256 tokensToBuy = (ethAmount * tokenAmount) / tokenPrice;
        
        // 从代币发行者那里购买代币用于流动性
        address creator = token.owner();
        token.transferFrom(creator, address(this), tokensToBuy);
        
        // 批准Router使用代币
        token.approve(address(uniswapRouter), tokensToBuy);
        
        // 添加流动性
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapRouter.addLiquidityETH{value: ethAmount}(
            tokenAddr,
            tokensToBuy,
            0, // 最小代币数量
            0, // 最小ETH数量
            address(this), // 流动性代币接收者
            block.timestamp + 300 // 5分钟超时
        );
        
        emit LiquidityAdded(tokenAddr, amountETH, amountToken);
    }
    
    // 紧急提取函数（仅owner可调用）
    function emergencyWithdraw() external onlyOwner {
        address payable ownerAddress = payable(owner());
        (bool success, ) = ownerAddress.call{value: address(this).balance}("");
        require(success, "Emergency withdraw failed");
    }
} 