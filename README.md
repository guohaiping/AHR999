# AHR999指数监控

这是一个自动获取AHR999指数的Docker应用，支持多架构部署，每周自动运行并通过Server酱发送通知。

## 功能特点

- 🔄 自动获取最新的AHR999指数
- 🐳 支持Docker容器化部署
- 🏗️ **多架构支持** - 兼容 x86_64 和 ARM64 架构
- ⏰ 每周日早上9点（北京时间）自动运行
- 📱 通过Server酱发送通知
- 🛡️ 错误处理和通知
- 📋 内置定时任务管理

## 支持的架构

| 架构 | 浏览器 | ChromeDriver | 适用设备 |
|------|--------|--------------|----------|
| **linux/amd64** | Google Chrome | 最新版本 | Intel/AMD服务器、个人电脑 |
| **linux/arm64** | Chromium | 系统版本 | Apple M1/M2、树莓派、ARM云服务器 |

## 系统要求

- Docker (支持 buildx 的版本推荐)
- Docker Compose
- 至少1GB可用内存
- 网络连接（用于访问外部服务）

## 快速开始

### 方法1: Docker Compose (推荐)

```bash
# 1. 克隆仓库
git clone https://github.com/guohaiping/AHR999.git
cd AHR999

# 2. 设置环境变量
export SERVER_CHAN_SCKEY="你的Server酱SCKEY"
# 或创建 .env 文件
echo "SERVER_CHAN_SCKEY=你的Server酱SCKEY" > .env

# 3. 启动服务（自动检测架构）
docker-compose up -d

# 4. 查看日志
docker-compose logs -f
```

### 方法2: 使用管理脚本

```bash
# 测试多架构支持
./scripts/ahr999.sh test

# 构建多架构镜像
./scripts/ahr999.sh build

# 部署服务
./scripts/ahr999.sh deploy

# 查看服务状态
./scripts/ahr999.sh status
```

### 方法3: 直接使用 Docker

```bash
# 构建镜像（自动检测当前架构）
docker build -t ahr999:latest .

# 运行容器
docker run -d \
  --name ahr999 \
  --network host \
  -e SERVER_CHAN_SCKEY="你的Server酱SCKEY" \
  ahr999:latest
```

## 项目结构

```
AHR999/
├── arh999.py                    # 主程序脚本
├── Dockerfile                   # 多架构Docker镜像构建文件
├── docker-compose.yml           # Docker Compose配置文件
├── requirements.txt             # Python依赖文件
├── .gitignore                   # Git忽略文件配置
└── scripts/                     # 脚本目录
    └── ahr999.sh                # 多功能管理脚本
```

## 管理脚本

项目提供了一个统一的管理脚本 `scripts/ahr999.sh`，包含以下功能：

```bash
# 查看帮助
./scripts/ahr999.sh help

# 测试多架构支持
./scripts/ahr999.sh test

# 构建镜像
./scripts/ahr999.sh build [tag] [registry]

# 部署服务
./scripts/ahr999.sh deploy

# 查看服务状态
./scripts/ahr999.sh status

# 查看服务日志
./scripts/ahr999.sh logs

# 清理资源
./scripts/ahr999.sh clean
```

## 环境变量

- `SERVER_CHAN_SCKEY`: Server酱的SCKEY，用于发送通知

## 运行和管理

容器启动后会自动运行cron服务，每周日早上9点（北京时间）自动执行脚本。

### 常用管理命令

```bash
# 查看服务状态
./scripts/ahr999.sh status

# 查看服务日志
./scripts/ahr999.sh logs

# 手动运行脚本测试
docker exec -it ahr999-new python3 /app/arh999.py

# 测试多架构支持
./scripts/ahr999.sh test

# 清理资源
./scripts/ahr999.sh clean
```

## 故障排除

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| Chrome/Chromium 启动失败 | 确保至少1GB内存，ARM64系统需要更多启动时间 |
| Server酱通知失败 | 检查 `SERVER_CHAN_SCKEY` 环境变量设置 |
| 定时任务不运行 | 使用 `./scripts/ahr999.sh status` 检查容器状态 |
| ChromeDriver 版本不匹配 | x86_64自动更新，ARM64使用系统版本 |
| 内存不足 | 增加Docker内存限制：`--memory=1g` |
| 网络连接问题 | 检查防火墙和网络配置 |

### 调试命令

```bash
# 运行完整测试
./scripts/ahr999.sh test

# 查看详细日志
./scripts/ahr999.sh logs

# 进入容器调试
docker exec -it ahr999-new bash

# 手动运行脚本
docker exec -it ahr999-new python3 /app/arh999.py
```

## 性能对比

| 架构 | 启动时间 | 内存使用 | CPU 使用 |
|------|----------|----------|----------|
| x86_64 | ~30s | ~200MB | 中等 |
| ARM64 | ~45s | ~180MB | 较低 |

## 高级功能

### 构建自定义镜像

```bash
# 构建本地镜像
./scripts/ahr999.sh build

# 构建指定标签
./scripts/ahr999.sh build v1.0

# 构建并推送到仓库
./scripts/ahr999.sh build latest your-registry.com/user
```

### 更新和维护

```bash
# 重新部署服务
./scripts/ahr999.sh deploy

# 清理旧资源
./scripts/ahr999.sh clean
```

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request 