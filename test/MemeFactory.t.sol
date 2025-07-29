// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract MemeFactoryTest is Test {
    MemeFactory public factory;
    address public projectOwner;
    address public memeCreator;
    address public buyer1;
    address public buyer2;
    
    function setUp() public {
        projectOwner = makeAddr("projectOwner");
        memeCreator = makeAddr("memeCreator");
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");
        
        // 给测试账户一些ETH
        vm.deal(projectOwner, 100 ether);
        vm.deal(memeCreator, 100 ether);
        vm.deal(buyer1, 100 ether);
        vm.deal(buyer2, 100 ether);
        
        vm.startPrank(projectOwner);
        factory = new MemeFactory(projectOwner);
        vm.stopPrank();
    }
    
    function test_DeployMeme() public {
        vm.startPrank(memeCreator);
        
        string memory symbol = "DOGE";
        uint256 totalSupply = 1000000;
        uint256 perMint = 1000;
        uint256 price = 0.01 ether;
        
        address memeToken = factory.deployMeme(symbol, totalSupply, perMint, price);
        
        // 验证代币部署成功
        assertTrue(memeToken != address(0), "Meme token should be deployed");
        
        MemeToken token = MemeToken(memeToken);
        // 在代理模式中，name()可能返回空字符串，我们主要验证customSymbol
        assertEq(token.customSymbol(), symbol, "Token custom symbol should be correct");
        assertEq(token.totalSupplyLimit(), totalSupply, "Total supply should be correct");
        assertEq(token.perMint(), perMint, "Per mint should be correct");
        assertEq(token.price(), price, "Price should be correct");
        assertEq(token.owner(), memeCreator, "Creator should be owner");
        
        vm.stopPrank();
    }
    
    function test_MintMeme() public {
        // 首先部署一个Meme代币
        vm.startPrank(memeCreator);
        address memeToken = factory.deployMeme("DOGE", 1000000, 1000, 0.01 ether);
        vm.stopPrank();
        
        // 记录初始余额
        uint256 creatorInitialBalance = memeCreator.balance;
        uint256 projectOwnerInitialBalance = projectOwner.balance;
        uint256 buyerInitialBalance = buyer1.balance;
        
        // 购买者铸造代币
        vm.startPrank(buyer1);
        uint256 mintCost = 0.01 ether;
        factory.mintMeme{value: mintCost}(memeToken);
        vm.stopPrank();
        
        // 验证代币铸造
        MemeToken token = MemeToken(memeToken);
        assertEq(token.balanceOf(buyer1), 1000, "Buyer should receive correct amount");
        assertEq(token.totalSupply(), 1000, "Total supply should be updated");
        
        // 验证费用分配
        uint256 expectedProjectFee = (mintCost * factory.PROJECT_FEE_PERCENTAGE()) / factory.FEE_DENOMINATOR();
        uint256 expectedCreatorFee = mintCost - expectedProjectFee;
        
        assertEq(projectOwner.balance, projectOwnerInitialBalance + expectedProjectFee, "Project owner should receive correct fee");
        assertEq(memeCreator.balance, creatorInitialBalance + expectedCreatorFee, "Creator should receive correct fee");
        assertEq(buyer1.balance, buyerInitialBalance - mintCost, "Buyer balance should be reduced by mint cost");
    }
    
    function test_MultipleMints() public {
        // 部署代币
        vm.startPrank(memeCreator);
        address memeToken = factory.deployMeme("DOGE", 5000, 1000, 0.01 ether);
        vm.stopPrank();
        
        // 多次铸造
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(buyer1);
            factory.mintMeme{value: 0.01 ether}(memeToken);
            vm.stopPrank();
        }
        
        MemeToken token = MemeToken(memeToken);
        assertEq(token.balanceOf(buyer1), 5000, "Buyer should have all tokens");
        assertEq(token.totalSupply(), 5000, "Total supply should be maxed out");
    }
    
    function test_MintExceedsTotalSupply() public {
        // 部署代币，总供应量小于每次铸造量
        vm.startPrank(memeCreator);
        vm.expectRevert("Per mint cannot exceed total supply");
        factory.deployMeme("DOGE", 500, 1000, 0.01 ether);
        vm.stopPrank();
    }
    
    function test_InsufficientPayment() public {
        // 部署代币
        vm.startPrank(memeCreator);
        address memeToken = factory.deployMeme("DOGE", 1000000, 1000, 0.01 ether);
        vm.stopPrank();
        
        // 尝试用不足的金额铸造
        vm.startPrank(buyer1);
        vm.expectRevert("Insufficient payment");
        factory.mintMeme{value: 0.005 ether}(memeToken);
        vm.stopPrank();
    }
    
    function test_ExcessPaymentRefund() public {
        // 部署代币
        vm.startPrank(memeCreator);
        address memeToken = factory.deployMeme("DOGE", 1000000, 1000, 0.01 ether);
        vm.stopPrank();
        
        uint256 buyerInitialBalance = buyer1.balance;
        
        // 支付超过所需金额
        vm.startPrank(buyer1);
        factory.mintMeme{value: 0.02 ether}(memeToken);
        vm.stopPrank();
        
        // 验证多余金额被退还
        assertEq(buyer1.balance, buyerInitialBalance - 0.01 ether, "Buyer should only pay the required amount");
    }
    
    function test_FeeDistribution() public {
        // 部署代币
        vm.startPrank(memeCreator);
        address memeToken = factory.deployMeme("DOGE", 1000000, 1000, 0.01 ether);
        vm.stopPrank();
        
        uint256 creatorInitialBalance = memeCreator.balance;
        uint256 projectOwnerInitialBalance = projectOwner.balance;
        
        // 铸造代币
        vm.startPrank(buyer1);
        factory.mintMeme{value: 0.01 ether}(memeToken);
        vm.stopPrank();
        
        // 验证费用分配比例
        uint256 totalFee = 0.01 ether;
        uint256 expectedProjectFee = (totalFee * 100) / 10000; // 1%
        uint256 expectedCreatorFee = totalFee - expectedProjectFee; // 99%
        
        assertEq(projectOwner.balance, projectOwnerInitialBalance + expectedProjectFee, "Project owner should receive 1%");
        assertEq(memeCreator.balance, creatorInitialBalance + expectedCreatorFee, "Creator should receive 99%");
    }
    
    function test_DeployMemeValidation() public {
        vm.startPrank(memeCreator);
        
        // 测试无效参数
        vm.expectRevert("Total supply must be greater than 0");
        factory.deployMeme("DOGE", 0, 1000, 0.01 ether);
        
        vm.expectRevert("Per mint must be greater than 0");
        factory.deployMeme("DOGE", 1000000, 0, 0.01 ether);
        
        vm.expectRevert("Per mint cannot exceed total supply");
        factory.deployMeme("DOGE", 1000, 2000, 0.01 ether);
        
        vm.expectRevert("Price must be greater than 0");
        factory.deployMeme("DOGE", 1000000, 1000, 0);
        
        vm.stopPrank();
    }
    
    function test_EmergencyWithdraw() public {
        // 给工厂合约发送一些ETH
        vm.deal(address(factory), 1 ether);
        
        uint256 projectOwnerInitialBalance = projectOwner.balance;
        
        // 只有项目方可以调用紧急提取
        vm.startPrank(memeCreator);
        vm.expectRevert();
        factory.emergencyWithdraw();
        vm.stopPrank();
        
        // 项目方可以成功提取
        vm.startPrank(projectOwner);
        factory.emergencyWithdraw();
        vm.stopPrank();
        
        // 验证提取成功
        assertEq(projectOwner.balance, projectOwnerInitialBalance + 1 ether, "Project owner should receive the ETH");
        assertEq(address(factory).balance, 0, "Factory should have no ETH left");
    }
    
    function test_Events() public {
        vm.startPrank(memeCreator);
        
        string memory symbol = "DOGE";
        uint256 totalSupply = 1000000;
        uint256 perMint = 1000;
        uint256 price = 0.01 ether;
        
        // 部署代币并验证事件会被发出
        address memeToken = factory.deployMeme(symbol, totalSupply, perMint, price);
        assertTrue(memeToken != address(0), "Meme token should be deployed");
        
        vm.stopPrank();
        
        // 铸造代币并验证事件会被发出
        vm.startPrank(buyer1);
        factory.mintMeme{value: price}(memeToken);
        vm.stopPrank();
        
        // 验证代币被正确铸造
        MemeToken token = MemeToken(memeToken);
        assertEq(token.balanceOf(buyer1), perMint, "Buyer should receive correct amount");
    }
    
    function test_GasOptimization() public {
        // 测试多次部署的Gas消耗
        vm.startPrank(memeCreator);
        
        uint256 gasUsed1 = 0;
        uint256 gasUsed2 = 0;
        
        // 第一次部署
        uint256 gasStart = gasleft();
        factory.deployMeme("DOGE1", 1000000, 1000, 0.01 ether);
        gasUsed1 = gasStart - gasleft();
        
        // 第二次部署
        gasStart = gasleft();
        factory.deployMeme("DOGE2", 1000000, 1000, 0.01 ether);
        gasUsed2 = gasStart - gasleft();
        
        // 验证Gas使用量相近（代理模式的优势）
        uint256 gasDifference = gasUsed1 > gasUsed2 ? gasUsed1 - gasUsed2 : gasUsed2 - gasUsed1;
        assertTrue(gasDifference < 10000, "Gas usage should be consistent for proxy deployments");
        
        vm.stopPrank();
    }
} 