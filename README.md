# AHR999指数监控

这是一个自动获取AHR999指数的Docker应用，支持每周自动运行并通过Server酱发送通知。

## 功能特点

- 自动获取最新的AHR999指数
- 支持Docker容器化部署
- 每周日早上9点（北京时间）自动运行
- 通过Server酱发送通知
- 错误处理和通知
- 内置定时任务管理

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

2. 创建环境变量文件：
```bash
echo "SERVER_CHAN_SCKEY=你的Server酱SCKEY" > .env
```

3. 构建并运行Docker容器：
```bash
sudo docker-compose up -d --build
```

## 环境变量

- `SERVER_CHAN_SCKEY`: Server酱的SCKEY，用于发送通知

## 文件说明

- `arh999.py`: 主程序脚本
- `Dockerfile`: Docker镜像构建文件
- `docker-compose.yml`: Docker Compose配置文件
- `requirements.txt`: Python依赖文件

## 运行说明

容器启动后会自动运行cron服务，每周日早上9点（北京时间）自动执行脚本。

查看运行日志：
```bash
sudo docker-compose logs -f
```

## 故障排除

1. 如果遇到Chrome启动问题，请确保：
   - 系统有足够的内存（至少1GB）
   - Docker容器有足够的资源限制

2. 如果Server酱通知失败：
   - 检查`docker-compose.yml`或`.env`文件中的`SERVER_CHAN_SCKEY`是否正确设置。
   - 确认网络连接正常。
   - **执行部署后验证**，确保密钥已加载到容器中。

3. 如果定时任务不运行：
   - 检查容器是否正常运行
   - 查看容器日志是否有错误信息

## 部署后验证

修改`docker-compose.yml`或`.env`文件后，需要强制重新创建容器才能让环境变量生效。

```bash
sudo docker-compose up -d --force-recreate
```

容器重启后，可以通过以下命令检查`SERVER_CHAN_SCKEY`是否被成功加载到容器的环境变量缓存文件中。可以通过`sudo docker ps`查看实际的容器名称。

```bash
# 注意将 ahr999-ahr999-1 替换为你的实际容器名
sudo docker exec ahr999-ahr999-1 cat /app/container_env
```
如果输出的内容中包含`SERVER_CHAN_SCKEY=你的密钥`，则说明配置成功。

## 手动触发测试

如果想立即测试一次数据获取和推送功能，而不是等待定时任务，可以执行以下命令手动触发脚本：

```bash
# 注意将 ahr999-ahr999-1 替换为你的实际容器名
sudo docker exec ahr999-ahr999-1 /usr/local/bin/python3 /app/arh999.py
```
**注意**：此命令直接在容器内执行脚本，会使用容器内的环境变量，可以完整地模拟定时任务的实际运行情况。

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request 