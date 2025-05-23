#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import requests
import os
import logging

def send_server_chan(title, content):
    sckey = os.getenv('SERVER_CHAN_SCKEY')
    if not sckey:
        logging.warning("未设置SERVER_CHAN_SCKEY环境变量")
        return
    
    url = f"https://sctapi.ftqq.com/{sckey}.send"
    data = {
        "title": title,
        "desp": content
    }
    response = requests.post(url, data=data)
    if response.status_code == 200:
        logging.info("Server酱通知发送成功")
    else:
        logging.error(f"Server酱通知发送失败: {response.text}")

def get_latest_ahr999():
    url = 'https://www.coinglass.com/zh/pro/i/ahr999'
    driver = None  # Initialize driver to None

    # 启动无头浏览器
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    
    # 根据环境变量设置浏览器路径
    chrome_bin = os.getenv('CHROME_BIN')
    if chrome_bin:
        options.binary_location = chrome_bin
    
    # service = ChromeService(executable_path='/usr/bin/chromedriver')
    service = ChromeService(ChromeDriverManager().install())
    
    try:
        driver = webdriver.Chrome(service=service, options=options)
        driver.get(url)

        # 最多等 15 秒，直到找到第一行 tr[data-row-key]
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'tr[data-row-key]'))
        )

        # 数据加载完成后再取 page_source
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        row = soup.find('tr', {'data-row-key': True})
        # 再次判断，避免万一
        if not row:
            raise RuntimeError("页面加载完成，但仍未定位到数据行，请检查 CSS 选择器。")

        date = row.find_all('td')[0].div.text.strip()
        value = row.find_all('td')[1].div.text.strip()
        return date, value
    except Exception as e:
        logging.error(f"Error during WebDriver operation in get_latest_ahr999: {e}") 
        raise # Re-raise to be handled by the main script's error handler
    finally:
        if driver:
            driver.quit()

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    try:
        date, value = get_latest_ahr999()
        message = f"{date} 的 AHR999 指数值：{value}"
        logging.info(message)
        send_server_chan("AHR999指数更新", message)
    except Exception as e:
        error_message = f"获取AHR999指数失败: {str(e)}"
        logging.error(error_message)
        send_server_chan("AHR999指数获取失败", error_message)