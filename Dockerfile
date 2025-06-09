FROM python:3.9-slim

# 设置时区为北京时间
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装浏览器和必要的依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    cron \
    tzdata \
    && if [ "$(uname -m)" = "x86_64" ]; then \
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
        && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
        && apt-get update \
        && apt-get install -y google-chrome-stable \
        && CHROME_BIN=/usr/bin/google-chrome; \
    else \
        apt-get install -y chromium chromium-driver \
        && CHROME_BIN=/usr/bin/chromium; \
    fi \
    && rm -rf /var/lib/apt/lists/*

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
RUN touch /var/log/cron.log
# 创建日志文件
RUN touch /var/log/cron.log

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV CHROME_BIN=${CHROME_BIN}

# 创建启动脚本
RUN echo '#!/bin/sh
touch /var/log/cron.log
cron
echo "Cron daemon started. Tailing /var/log/cron.log..."
tail -f /var/log/cron.log' > /app/start.sh
RUN chmod +x /app/start.sh

# 运行启动脚本
CMD ["/app/start.sh"] 