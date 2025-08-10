// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../IUniswapV2Router02.sol";
import "../IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUniswapV2Router is IUniswapV2Router02 {
    IUniswapV2Factory public immutable uniswapFactory;
    address public immutable WETH;

    constructor(address _factory, address _WETH) {
        uniswapFactory = IUniswapV2Factory(_factory);
        WETH = _WETH;
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        require(deadline >= block.timestamp, "EXPIRED");
        // 模拟从发送者转移代币到这个mock router
        IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        
        // 模拟配对创建（如果不存在）
        if (uniswapFactory.getPair(token, WETH) == address(0)) {
            uniswapFactory.createPair(token, WETH);
        }

        // 返回测试用的虚拟值
        return (amountTokenDesired, msg.value, 1000);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        require(path.length == 2, "Path must be 2");
        require(path[0] == WETH, "Path must start with WETH");
        require(deadline >= block.timestamp, "EXPIRED");

        // 模拟接收ETH并发送代币
        // 为了简单起见，假设1:1的比例
        uint256 receivedETH = msg.value;
        uint256 tokensToReturn = receivedETH * 100; // 示例：1 ETH = 100 tokens
        
        require(tokensToReturn >= amountOutMin, "Insufficient output amount");

        IERC20(path[1]).transfer(to, tokensToReturn);

        amounts = new uint256[](2);
        amounts[0] = receivedETH;
        amounts[1] = tokensToReturn;
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts) {
        require(path.length == 2, "Path must be 2");
        require(path[0] == WETH, "Path must start with WETH");
        // 模拟一个简单的价格用于测试
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn * 100; // 示例：1 ETH = 100 tokens
    }
    
    function factory() external pure returns (address) {
        return address(0); // 返回一个虚拟地址，实际测试中不会用到
    }
}
