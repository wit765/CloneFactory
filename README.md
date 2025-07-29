## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Meme 发射平台

这是一个基于EVM链的Meme代币发射平台，使用最小代理模式来减少Gas成本。每个Meme都是一个ERC20代币，用户可以通过工厂合约快速创建和铸造Meme代币。

## 功能特性

- **最小代理模式**: 使用OpenZeppelin的Clones库实现，大幅降低部署Gas成本
- **公平铸造**: 每次铸造固定数量的代币，避免一次性全部铸造
- **费用分配**: 铸造费用按比例分配给项目方(1%)和代币发行者(99%)
- **安全验证**: 完整的参数验证和边界检查
- **事件记录**: 详细的事件记录用于前端集成

## 合约架构

### MemeToken.sol
- 继承OpenZeppelin的ERC20和Ownable
- 支持代理模式初始化
- 包含总供应量、每次铸造量和价格参数
- 只有owner可以铸造代币

### MemeFactory.sol
- 使用最小代理模式部署Meme代币
- 提供`deployMeme`方法创建新代币
- 提供`mintMeme`方法铸造代币
- 自动处理费用分配和退款

## 主要方法

### deployMeme
```solidity
function deployMeme(
    string memory symbol,
    uint256 totalSupply,
    uint256 perMint,
    uint256 price
) external returns (address)
```

**参数说明:**
- `symbol`: 代币符号（如"DOGE"）
- `totalSupply`: 总发行量
- `perMint`: 每次铸造数量
- `price`: 每次铸造价格（wei）

**返回值:** 新部署的代币合约地址

### mintMeme
```solidity
function mintMeme(address tokenAddr) external payable
```

**参数说明:**
- `tokenAddr`: 要铸造的代币合约地址
- `msg.value`: 支付金额（必须 >= 代币价格）

## 费用分配

每次铸造的费用分配如下：
- **项目方**: 1% (100/10000)
- **代币发行者**: 99% (9900/10000)

## 安装和测试

### 安装依赖
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

### 编译合约
```bash
forge build
```

### 运行测试
```bash
forge test
```

### 运行特定测试
```bash
forge test --match-test test_MintMeme -vv
```

## 测试用例

项目包含完整的测试覆盖：

1. **基本功能测试**
   - 代币部署验证
   - 代币铸造验证
   - 多次铸造测试

2. **边界条件测试**
   - 超过总供应量限制
   - 支付金额不足
   - 多余金额退款

3. **费用分配测试**
   - 验证1%项目方费用
   - 验证99%发行者费用

4. **安全测试**
   - 参数验证
   - 权限控制
   - 紧急提取功能

5. **Gas优化测试**
   - 验证代理模式的Gas节省

## 部署

### 设置环境变量
```bash
export PRIVATE_KEY=your_private_key_here
```

### 部署合约
```bash
forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --broadcast
```

## 使用示例

### 1. 部署Meme代币
```javascript
// 调用deployMeme方法
const tx = await factory.deployMeme("DOGE", 1000000, 1000, ethers.utils.parseEther("0.01"));
const receipt = await tx.wait();
const event = receipt.events.find(e => e.event === "MemeDeployed");
const tokenAddress = event.args.token;
```

### 2. 铸造Meme代币
```javascript
// 调用mintMeme方法
const price = ethers.utils.parseEther("0.01");
const tx = await factory.mintMeme(tokenAddress, { value: price });
await tx.wait();
```

## 安全考虑

- 使用OpenZeppelin的经过审计的合约
- 完整的参数验证
- 重入攻击防护
- 权限控制
- 紧急提取功能

## 许可证

MIT License
