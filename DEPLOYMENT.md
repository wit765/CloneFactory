# 部署指南

## 前置要求

1. 安装 Foundry
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. 安装依赖
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

## 环境设置

1. 创建 `.env` 文件
```bash
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

2. 加载环境变量
```bash
source .env
```

## 编译合约

```bash
forge build
```

## 运行测试

```bash
# 运行所有测试
forge test

# 运行特定测试
forge test --match-test test_MintMeme

# 运行测试并显示详细输出
forge test -vvv

# 运行测试并生成覆盖率报告
forge coverage
```

## 部署到测试网

### 部署到 Sepolia 测试网

```bash
# 部署工厂合约
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify

# 运行示例脚本
forge script script/Example.s.sol --rpc-url $RPC_URL --broadcast

# 运行Gas分析
forge script script/GasAnalysis.s.sol --rpc-url $RPC_URL --broadcast
```

### 部署到本地网络

```bash
# 启动本地节点
anvil

# 在另一个终端部署
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

## 验证合约

```bash
# 验证工厂合约
forge verify-contract \
    --chain-id 11155111 \
    --compiler-version 0.8.20 \
    --constructor-args $(cast abi-encode "constructor(address)" "0xYourProjectOwnerAddress") \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    "0xYourFactoryAddress" \
    src/MemeFactory.sol:MemeFactory
```

## 合约地址

部署后，请记录以下地址：

- **MemeFactory**: `0x...`
- **MemeToken Implementation**: `0x...`

## 使用示例

### 1. 创建新的Meme代币

```javascript
const factory = await ethers.getContractAt("MemeFactory", factoryAddress);

const tx = await factory.deployMeme(
    "DOGE",           // symbol
    "1000000",        // totalSupply
    "1000",           // perMint
    ethers.utils.parseEther("0.01") // price
);

const receipt = await tx.wait();
const event = receipt.events.find(e => e.event === "MemeDeployed");
const tokenAddress = event.args.token;
console.log("New meme token deployed at:", tokenAddress);
```

### 2. 铸造Meme代币

```javascript
const price = ethers.utils.parseEther("0.01");
const tx = await factory.mintMeme(tokenAddress, { value: price });
await tx.wait();
console.log("Successfully minted meme tokens");
```

## 监控和调试

### 查看事件日志

```bash
# 查看部署事件
cast logs --from-block 0 --address 0xYourFactoryAddress

# 查看铸造事件
cast logs --from-block 0 --address 0xYourFactoryAddress --event "MemeMinted(address,address,uint256,uint256)"
```

### 查询合约状态

```bash
# 查询工厂合约信息
cast call 0xYourFactoryAddress "memeTokenImplementation()" --rpc-url $RPC_URL

# 查询代币信息
cast call 0xYourTokenAddress "getMintInfo()" --rpc-url $RPC_URL
```

## 故障排除

### 常见问题

1. **Gas不足**
   - 增加Gas限制
   - 检查Gas价格设置

2. **验证失败**
   - 确保编译器版本匹配
   - 检查构造函数参数

3. **交易失败**
   - 检查账户余额
   - 验证合约地址

### 调试命令

```bash
# 查看交易详情
cast tx 0xYourTransactionHash --rpc-url $RPC_URL

# 查看合约代码
cast code 0xYourContractAddress --rpc-url $RPC_URL

# 查看账户余额
cast balance 0xYourAddress --rpc-url $RPC_URL
```

## 安全注意事项

1. **私钥安全**
   - 永远不要在代码中硬编码私钥
   - 使用环境变量或安全的密钥管理

2. **合约验证**
   - 部署后立即验证合约
   - 检查合约地址和ABI

3. **测试**
   - 在测试网上充分测试
   - 验证所有功能正常工作

## 支持

如果遇到问题，请检查：
1. Foundry版本是否最新
2. 依赖是否正确安装
3. 网络连接是否正常
4. 账户是否有足够余额 