# AHR999指数监控

这是一个自动获取AHR999指数的Docker应用，支持每周自动运行并通过Server酱发送通知。

## 功能特点

- 自动获取最新的AHR999指数
- 支持Docker容器化部署
- 每周日早上9点（北京时间）自动运行
- 通过Server酱发送通知
- 错误处理和通知
- 内置定时任务管理
- 同时支持ARM和x86架构

## 系统要求

- Docker
- Docker Compose
- 至少1GB可用内存
- 网络连接（用于访问外部服务）

## 安装步骤

1. 克隆仓库：
```bash
git clone https://github.com/guohaiping/AHR999.git
cd AHR999
```

2. 复制并修改环境变量示例文件：
```bash
cp env.example .env
# 然后编辑 .env 文件，填入你的 Server 酱 SCKEY
```

3. 构建并运行 Docker 容器：
```bash
sudo docker-compose up -d --build
```

## 环境变量

- `SERVER_CHAN_SCKEY`: Server酱的 SCKEY，用于发送通知

## 文件说明

- `arh999.py`: 主程序脚本
- `Dockerfile`: Docker 镜像构建文件
- `docker-compose.yml`: Docker Compose 配置文件
- `requirements.txt`: Python 依赖文件

## 跨平台支持

该应用程序自动适配运行环境，支持：

- **ARM 架构**：如树莓派、Oracle ARM 实例等，使用 Chromium 浏览器
- **x86_64 架构**：传统服务器，使用 Google Chrome

程序会自动检测系统架构并安装合适的浏览器和驱动程序，无需额外配置。

## 运行说明

容器启动后会自动运行 cron 服务，每周日早上 9 点（北京时间）自动执行脚本。

查看运行日志：
```bash
sudo docker-compose logs -f
```

## 故障排除

1. 如果遇到 Chrome 启动问题，请确保：
   - 系统有足够的内存（至少 1GB）
   - Docker 容器有足够的资源限制

2. 如果 Server 酱通知失败：
   - 检查 `docker-compose.yml` 或 `.env` 文件中的 `SERVER_CHAN_SCKEY` 是否正确设置。
   - 确认网络连接正常。
   - **执行部署后验证**，确保密钥已加载到容器中。

3. 如果定时任务不运行：
   - 检查容器是否正常运行
   - 查看容器日志是否有错误信息

## 部署后验证

修改 `docker-compose.yml` 或 `.env` 文件后，需要强制重新创建容器才能让环境变量生效。

```bash
sudo docker-compose up -d --force-recreate
```

容器重启后，可以通过以下命令检查 `SERVER_CHAN_SCKEY` 是否被成功加载到容器的环境变量缓存文件中。可以通过 `sudo docker ps` 查看实际的容器名称。

```bash
# 注意将 ahr999-ahr999-1 替换为你的实际容器名
sudo docker exec ahr999-ahr999-1 cat /app/container_env
```
如果输出的内容中包含 `SERVER_CHAN_SCKEY=你的密钥`，则说明配置成功。

## 手动触发测试

如果想立即测试一次数据获取和推送功能，而不是等待定时任务，可以执行以下命令手动触发脚本：

```bash
# 注意将 ahr999-ahr999-1 替换为你的实际容器名
sudo docker exec ahr999-ahr999-1 /usr/local/bin/python3 /app/arh999.py
```
**注意**：此命令直接在容器内执行脚本，会使用容器内的环境变量，可以完整地模拟定时任务的实际运行情况。

## 免责声明

本仓库仅供技术研究与学习参考，指数数据来源于第三方网站 CoinGlass。AHR999 指数并非投资建议；使用本软件可能涉及的任何法律合规风险和经济损失，作者概不负责。请用户在使用前自行评估风险并遵守当地法律法规。

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request