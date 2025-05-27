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

def send_server_chan(title, content):
    sckey = os.getenv('SERVER_CHAN_SCKEY')
    if not sckey:
        print("未设置SERVER_CHAN_SCKEY环境变量")
        return
    
    url = f"https://sctapi.ftqq.com/{sckey}.send"
    data = {
        "title": title,
        "desp": content
    }
    response = requests.post(url, data=data)
    if response.status_code == 200:
        print("Server酱通知发送成功")
    else:
        print(f"Server酱通知发送失败: {response.text}")

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
    
    # 设置浏览器路径为chromium
    options.binary_location = '/usr/bin/chromium'
    
    print("正在启动浏览器...")
    service = ChromeService(executable_path='/usr/bin/chromedriver')
    
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
        send_server_chan("AHR999指数更新", message)
    except Exception as e:
        error_message = f"获取AHR999指数失败: {str(e)}"
        print(error_message)
        print("完整错误信息:")
        traceback.print_exc()
        send_server_chan("AHR999指数获取失败", error_message)