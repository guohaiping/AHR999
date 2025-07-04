#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import requests
import os
import traceback
import time
import re
import shutil

def load_env_from_file():
    """从container_env文件加载环境变量"""
    try:
        if os.path.exists('/app/container_env'):
            print("从container_env文件加载环境变量")
            with open('/app/container_env', 'r') as f:
                for line in f:
                    # 忽略注释和空行
                    if not line.strip() or line.strip().startswith('#'):
                        continue
                    # 解析KEY=VALUE格式
                    match = re.match(r'([^=]+)=(.*)', line.strip())
                    if match:
                        key, value = match.groups()
                        # 只设置未定义的环境变量
                        if key not in os.environ:
                            os.environ[key] = value
                            print(f"从文件设置环境变量: {key}")
    except Exception as e:
        print(f"加载环境变量文件出错: {e}")

def send_server_chan(title, content):
    # 首先尝试直接从环境变量获取
    sckey = os.getenv('SERVER_CHAN_SCKEY')

    # 如果没有找到，尝试从文件加载环境变量
    if not sckey:
        load_env_from_file()
        sckey = os.getenv('SERVER_CHAN_SCKEY')

    if not sckey:
        print("未设置SERVER_CHAN_SCKEY环境变量")
        print("当前环境变量:")
        for key, value in os.environ.items():
            if 'SERVER' in key or 'SCKEY' in key:
                print(f"  {key}={value}")
        return

    url = f"https://sctapi.ftqq.com/{sckey}.send"
    data = {
        "title": title,
        "desp": content
    }

    print(f"准备向Server酱发送通知，SCKEY长度: {len(sckey)}")

    # 添加重试逻辑
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = requests.post(url, data=data, timeout=10)
            if response.status_code == 200:
                print("Server酱通知发送成功")
                return
            else:
                print(f"Server酱通知发送失败 (尝试 {attempt + 1}/{max_retries}): HTTP {response.status_code} - {response.text}")
        except Exception as e:
            print(f"发送通知时出错 (尝试 {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                time.sleep(2)  # 等待2秒后重试

    print("Server酱通知发送失败，已达到最大重试次数")

def get_latest_ahr999():
    url = 'https://www.coinglass.com/zh/pro/i/ahr999'

    # 启动无头浏览器
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-extensions')
    options.add_argument('--disable-web-security')
    options.add_argument('--disable-features=VizDisplayCompositor')
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
    
    # 检测并设置浏览器二进制文件路径
    chrome_paths = [
        '/usr/bin/chromium-browser',
        '/usr/bin/chromium',
        '/usr/bin/google-chrome',
        '/usr/bin/google-chrome-stable'
    ]
    
    chrome_binary = None
    for path in chrome_paths:
        if os.path.exists(path):
            chrome_binary = path
            print(f"找到浏览器路径: {chrome_binary}")
            break
            
    if not chrome_binary:
        raise RuntimeError("未找到Chrome或Chromium浏览器，请确保已安装")
    
    options.binary_location = chrome_binary
    
    # 检测并设置ChromeDriver路径
    chromedriver_paths = [
        '/usr/bin/chromedriver',
        '/usr/local/bin/chromedriver'
    ]
    
    chromedriver_path = None
    for path in chromedriver_paths:
        if os.path.exists(path):
            chromedriver_path = path
            print(f"找到ChromeDriver路径: {chromedriver_path}")
            break
            
    if not chromedriver_path:
        # 尝试通过which命令查找
        try:
            chromedriver_path = shutil.which('chromedriver')
            if chromedriver_path:
                print(f"通过which命令找到ChromeDriver: {chromedriver_path}")
        except Exception:
            pass
            
    if not chromedriver_path:
        raise RuntimeError("未找到ChromeDriver，请确保已安装")
    
    print("正在启动浏览器...")
    service = ChromeService(executable_path=chromedriver_path)
    
    try:
        driver = webdriver.Chrome(service=service, options=options)
        print("浏览器启动成功")
    except Exception as e:
        print(f"浏览器启动失败: {e}")
        traceback.print_exc()
        raise

    try:
        print(f"正在访问网页: {url}")
        driver.get(url)
        print("网页访问成功，等待页面加载...")
        
        # 等待更长时间让页面完全加载
        time.sleep(5)
        
        print("页面加载等待完成，正在查找数据元素...")

        # 最多等 30 秒，直到找到第一行 tr[data-row-key]
        WebDriverWait(driver, 30).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'tr[data-row-key]'))
        )
        print("找到数据行，开始解析...")

        # 数据加载完成后再取 page_source
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # 保存页面源码用于调试
        with open('/app/page_source.html', 'w', encoding='utf-8') as f:
            f.write(driver.page_source)
        print("页面源码已保存到 /app/page_source.html")
        
        row = soup.find('tr', {'data-row-key': True})
        # 再次判断，避免万一
        if not row:
            raise RuntimeError("页面加载完成，但仍未定位到数据行，请检查 CSS 选择器。")

        date = row.find_all('td')[0].div.text.strip()
        value = row.find_all('td')[1].div.text.strip()
        print(f"成功获取数据: {date} - {value}")
        return date, value

    except Exception as e:
        print(f"数据获取过程中出错: {e}")
        traceback.print_exc()
        # 保存页面源码用于调试
        try:
            with open('/app/error_page_source.html', 'w', encoding='utf-8') as f:
                f.write(driver.page_source)
            print("错误时的页面源码已保存到 /app/error_page_source.html")
        except:
            print("无法保存错误页面源码")
        raise
    finally:
        driver.quit()
        print("浏览器已关闭")

if __name__ == '__main__':
    try:
        date, value = get_latest_ahr999()
        message = f"{date} 的 AHR999 指数值：{value}"
        print(message)
        send_server_chan("AHR999指数更新"+value, message)
    except Exception as e:
        error_message = f"获取AHR999指数失败: {str(e)}"
        print(error_message)
        print("完整错误信息:")
        traceback.print_exc()
        send_server_chan("AHR999指数获取失败", error_message)