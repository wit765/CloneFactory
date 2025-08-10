// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract GasAnalysisScript is Script {
    function run() external {
        address projectOwner = makeAddr("projectOwner");
        address memeCreator = makeAddr("memeCreator");
        
        vm.startBroadcast();
        
        // 部署工厂合约
        // 注意：这里需要提供Uniswap Router和WETH地址，为了示例我们使用虚拟地址
        address mockUniswapRouter = makeAddr("mockUniswapRouter");
        address mockWETH = makeAddr("mockWETH");
        MemeFactory factory = new MemeFactory(projectOwner, mockUniswapRouter, mockWETH);
        console.log("=== Gas Analysis ===");
        console.log("Factory deployed at:", address(factory));
        
        // 分析代理模式部署的Gas成本
        console.log("\n=== Proxy Deployment Gas Analysis ===");
        
        uint256 totalGasUsed = 0;
        uint256[] memory gasUsed = new uint256[](5);
        
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(memeCreator);
            
            uint256 gasStart = gasleft();
            address memeToken = factory.deployMeme(
                string(abi.encodePacked("DOGE", vm.toString(i))),
                1000000,
                1000,
                0.01 ether
            );
            uint256 gasEnd = gasleft();
            
            gasUsed[i] = gasStart - gasEnd;
            totalGasUsed += gasUsed[i];
            
            console.log("Deployment", i + 1, "Gas used:", gasUsed[i]);
            console.log("Token address:", memeToken);
            
            vm.stopPrank();
        }
        
        console.log("\n=== Summary ===");
        console.log("Average gas per deployment:", totalGasUsed / 5);
        console.log("Total gas for 5 deployments:", totalGasUsed);
        
        // 估算传统部署的Gas成本（假设每个合约部署需要500,000 gas）
        uint256 traditionalGas = 500000 * 5;
        uint256 gasSaved = traditionalGas - totalGasUsed;
        uint256 gasSavedPercentage = (gasSaved * 100) / traditionalGas;
        
        console.log("\n=== Comparison ===");
        console.log("Traditional deployment gas (estimated):", traditionalGas);
        console.log("Proxy deployment gas:", totalGasUsed);
        console.log("Gas saved:", gasSaved);
        console.log("Gas saved percentage:", gasSavedPercentage, "%");
        
        // 分析铸造Gas成本
        console.log("\n=== Minting Gas Analysis ===");
        address testToken = factory.deployMeme("TEST", 1000000, 1000, 0.01 ether);
        
        vm.startPrank(memeCreator);
        uint256 mintGasStart = gasleft();
        factory.mintMeme{value: 0.01 ether}(testToken);
        uint256 mintGasEnd = gasleft();
        vm.stopPrank();
        
        console.log("Minting gas cost:", mintGasStart - mintGasEnd);
        
        vm.stopBroadcast();
    }
} 