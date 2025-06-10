# 多架构支持的Dockerfile
FROM python:3.9-slim

# 设置时区为北京时间
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 获取架构信息
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "Building on $BUILDPLATFORM, targeting $TARGETPLATFORM"

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    cron \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 根据架构安装Chrome/Chromium
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        # x86_64架构：安装Google Chrome
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
        echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
        apt-get update && \
        apt-get install -y google-chrome-stable && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        # ARM64架构：安装Chromium
        apt-get update && \
        apt-get install -y chromium chromium-driver && \
        rm -rf /var/lib/apt/lists/*; \
    else \
        # 其他架构：尝试安装Chromium
        apt-get update && \
        apt-get install -y chromium chromium-driver && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# 安装ChromeDriver（针对x86_64架构）
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        CHROMEDRIVER_VERSION=$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
        wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip" && \
        unzip /tmp/chromedriver.zip -d /tmp/ && \
        mv /tmp/chromedriver /usr/local/bin/chromedriver && \
        chmod +x /usr/local/bin/chromedriver && \
        rm /tmp/chromedriver.zip; \
    fi

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制脚本
COPY arh999.py .

# 创建cron任务（每周日上午9点执行）
RUN echo "0 9 * * 0 root export SERVER_CHAN_SCKEY=\$SERVER_CHAN_SCKEY && cd /app && /usr/local/bin/python3 arh999.py >> /var/log/cron.log 2>&1" > /etc/cron.d/ahr999-cron
RUN echo "" >> /etc/cron.d/ahr999-cron
RUN chmod 0644 /etc/cron.d/ahr999-cron

# 创建日志文件
RUN touch /var/log/cron.log

# 设置环境变量（根据架构设置Chrome路径）
ENV PYTHONUNBUFFERED=1
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        echo 'export CHROME_BIN=/usr/bin/google-chrome' >> /etc/environment && \
        echo 'export CHROMEDRIVER_PATH=/usr/local/bin/chromedriver' >> /etc/environment; \
    else \
        echo 'export CHROME_BIN=/usr/bin/chromium' >> /etc/environment && \
        echo 'export CHROMEDRIVER_PATH=/usr/bin/chromedriver' >> /etc/environment; \
    fi

# 创建启动脚本
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'source /etc/environment' >> /app/start.sh && \
    echo 'touch /var/log/cron.log' >> /app/start.sh && \
    echo 'cron' >> /app/start.sh && \
    echo 'echo "Cron daemon started. Architecture: $(uname -m)"' >> /app/start.sh && \
    echo 'echo "Chrome binary: $CHROME_BIN"' >> /app/start.sh && \
    echo 'echo "ChromeDriver path: $CHROMEDRIVER_PATH"' >> /app/start.sh && \
    echo 'echo "Tailing /var/log/cron.log..."' >> /app/start.sh && \
    echo 'tail -f /var/log/cron.log' >> /app/start.sh
RUN chmod +x /app/start.sh

# 运行启动脚本
CMD ["/app/start.sh"]