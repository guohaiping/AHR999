FROM python:3.9-slim

# 设置时区为北京时间
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装Chrome、cron和必要的依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    cron \
    tzdata \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制脚本
COPY arh999.py .

# 创建cron任务（每周日早上9点执行）
RUN echo "0 9 * * 0 cd /app && python arh999.py >> /var/log/cron.log 2>&1" > /etc/cron.d/ahr999-cron
RUN chmod 0644 /etc/cron.d/ahr999-cron

# 创建日志文件
RUN touch /var/log/cron.log

# 设置环境变量
ENV PYTHONUNBUFFERED=1

# 创建启动脚本
RUN echo '#!/bin/sh\nservice cron start\ntail -f /var/log/cron.log' > /app/start.sh
RUN chmod +x /app/start.sh

# 运行启动脚本
CMD ["/app/start.sh"] 