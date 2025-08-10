// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract ExampleScript is Script {
    function run() external {
        // 模拟不同的用户
        address projectOwner = makeAddr("projectOwner");
        address memeCreator = makeAddr("memeCreator");
        address buyer1 = makeAddr("buyer1");
        address buyer2 = makeAddr("buyer2");
        
        vm.startBroadcast();
        
        // 1. 项目方部署工厂合约
        // 注意：这里需要提供Uniswap Router和WETH地址，为了示例我们使用虚拟地址
        address mockUniswapRouter = makeAddr("mockUniswapRouter");
        address mockWETH = makeAddr("mockWETH");
        MemeFactory factory = new MemeFactory(projectOwner, mockUniswapRouter, mockWETH);
        console.log("MemeFactory deployed at:", address(factory));
        
        // 2. Meme发行者创建代币
        vm.startPrank(memeCreator);
        address memeToken = factory.deployMeme("DOGE", 1000000, 1000, 0.01 ether);
        console.log("MemeToken deployed at:", memeToken);
        console.log("Symbol: DOGE");
        console.log("Total Supply: 1,000,000");
        console.log("Per Mint: 1,000");
        console.log("Price: 0.01 ETH");
        vm.stopPrank();
        
        // 3. 用户购买代币
        vm.startPrank(buyer1);
        factory.mintMeme{value: 0.01 ether}(memeToken);
        console.log("Buyer1 minted 1,000 DOGE tokens");
        vm.stopPrank();
        
        vm.startPrank(buyer2);
        factory.mintMeme{value: 0.01 ether}(memeToken);
        console.log("Buyer2 minted 1,000 DOGE tokens");
        vm.stopPrank();
        
        // 4. 查看代币信息
        MemeToken token = MemeToken(memeToken);
        console.log("Total tokens minted:", token.totalSupply());
        console.log("Buyer1 balance:", token.balanceOf(buyer1));
        console.log("Buyer2 balance:", token.balanceOf(buyer2));
        
        // 5. 查看费用分配
        console.log("Project owner balance:", projectOwner.balance);
        console.log("Meme creator balance:", memeCreator.balance);
        
        vm.stopBroadcast();
    }
} 