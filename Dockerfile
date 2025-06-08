FROM python:3.9-slim

# 设置时区为北京时间
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 获取系统架构
RUN arch=$(dpkg --print-architecture) && echo "检测到系统架构: $arch"

# 安装浏览器和必要的依赖
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    unzip \
    cron \
    tzdata \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        echo "在x86_64架构上安装Google Chrome"; \
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
        && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
        && apt-get update \
        && apt-get install -y google-chrome-stable \
        && apt-get install -y chromium-driver; \
    else \
        echo "在非x86_64架构上安装Chromium"; \
        apt-get install -y chromium chromium-driver; \
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

# 创建环境变量保存脚本
RUN echo '#!/bin/sh\nenv > /app/container_env' > /app/save_env.sh
RUN chmod +x /app/save_env.sh

# 创建cron任务（每周日上午11点执行）
RUN echo "# 保存当前环境变量" > /etc/cron.d/ahr999-cron
RUN echo "* * * * * root /app/save_env.sh" >> /etc/cron.d/ahr999-cron
RUN echo "# 每周日上午11点执行AHR999脚本" >> /etc/cron.d/ahr999-cron
RUN echo "0 11 * * 0 root cd /app && . /app/container_env && /usr/local/bin/python3 arh999.py >> /var/log/cron.log 2>&1" >> /etc/cron.d/ahr999-cron
RUN echo "" >> /etc/cron.d/ahr999-cron
RUN chmod 0644 /etc/cron.d/ahr999-cron

# 创建日志文件
RUN touch /var/log/cron.log

# 设置环境变量
ENV PYTHONUNBUFFERED=1

# 确保chromedriver和浏览器可执行
RUN if [ -f /usr/bin/chromium ]; then chmod +x /usr/bin/chromium; fi
RUN if [ -f /usr/bin/chromium-browser ]; then chmod +x /usr/bin/chromium-browser; else if [ -f /usr/bin/chromium ]; then ln -sf /usr/bin/chromium /usr/bin/chromium-browser; fi; fi
RUN if [ -f /usr/bin/google-chrome ]; then chmod +x /usr/bin/google-chrome; fi
RUN if [ -f /usr/bin/chromedriver ]; then chmod +x /usr/bin/chromedriver; fi

# 创建启动脚本
RUN echo '#!/bin/sh\n# 保存环境变量\nenv > /app/container_env\nservice cron start\ntail -f /var/log/cron.log' > /app/start.sh
RUN chmod +x /app/start.sh

# 运行启动脚本
CMD ["/app/start.sh"] 