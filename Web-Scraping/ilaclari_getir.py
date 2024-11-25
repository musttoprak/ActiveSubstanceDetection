import os
import requests
import time
import json
import re
import mysql.connector
import configparser
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

def read_config():
    config = configparser.ConfigParser()
    config.read('config.ini', encoding='utf-8')
    return config

def start_driver(driver_path):
    options = webdriver.ChromeOptions()
    service = Service(executable_path=driver_path)
    return webdriver.Chrome(service=service, options=options)

def login():
    driver = start_driver(config['DEFAULT']['webdriver_path'])
    driver.get(config['DEFAULT']['login_url'])
    time.sleep(3)
    driver.find_element(By.NAME, 'email').send_keys(config['DEFAULT']['email'])
    driver.find_element(By.NAME, 'parola').send_keys(config['DEFAULT']['password'] + Keys.RETURN)
    
    return driver

def close_cookie_banner(driver):
    try:
        cookie_accept = driver.find_element(By.ID, 'cookiescript_accept')
        cookie_accept.click()
        print("Cookie banner closed successfully.")
    except Exception as e:
        print("Cookie banner couldn't be closed: ", e)

def get_tabs_content(driver, link):
    driver.get(link)  # Sayfayı yükle
    
    # Tab sekmeleri
    tabs = driver.find_elements(By.CSS_SELECTOR, "ul[data-toggle='tabs'] li")  # Tüm tab sekmelerini bul

    tab_data = {}  # Veriyi saklamak için bir dictionary
    
    product_name_element = driver.find_element(By.CSS_SELECTOR, "#isimHeader span[data-name='urun_adi']")
    product_name = product_name_element.text  # Ürün adı alınıyor
    tab_data["Adı"] = product_name
    
    for tab in tabs:
        # Eğer sekme görünürse, tıklayın
        if "display: none" not in tab.get_attribute("style"):
            tab_name = tab.text.strip()  # Sekme adını al
            tab.click()  # Sekmeye tıklayın
            time.sleep(1)  # Verilerin yüklenmesi için bekle

            # Tıklanan sekmenin içerik div'ini al
            href_value = tab.find_element(By.TAG_NAME, "a").get_attribute("href")
            tab_id = href_value.split("#")[1]  # href="#tab_anabilgi" kısmından "tab_anabilgi" kısmını al
            
            # İlgili content div'ini bul
            content_div = driver.find_element(By.ID, tab_id)
            
            # Veriyi al ve kaydet
            tab_data[tab_name] = content_div.get_attribute("outerHTML")  # İçeriği HTML olarak al

    return tab_data

def save_to_json(id,data, link):
    # URL'deki &u= parametresini çıkart ve dosya ismini oluştur
    match = re.search(r'&u=([^&=]+)', link)
    if match:
        file_name = f"ilaclar/{id}-{match.group(1)}.json" 
    else:
        file_name = f"ilaclar/data_default-{id}.json"
    
    # JSON verisini dosyaya kaydet
    with open(file_name, 'w', encoding='utf-8') as json_file:
        json.dump(data, json_file, ensure_ascii=False, indent=4)
    print(f"Veri {file_name} dosyasına kaydedildi.")

if __name__ == "__main__":
    config = read_config()

    db = mysql.connector.connect(
        host= config['DATABASE']['host'],
        user= config['DATABASE']['user'],
        password= config['DATABASE']['password'],
        database= config['DATABASE']['database']
    )

    cursor = db.cursor()
    driver = login()
    close_cookie_banner(driver)
    
    if driver:
        # Ziyaret edilen linkleri tutacak bir set oluştur
        visited_links = set()
        
        # Veritabanından linkleri al
        cursor.execute("SELECT id, link FROM preparations")  # `preparations` tablonuzdaki linkleri alıyoruz.
        rows = cursor.fetchall()

        # Her link için işlem yap
        for row in rows:
            id, link = row

            if link not in visited_links:
                visited_links.add(link)  # Linki ziyaret edilenler listesine ekle
                
                # Sekmeleri al ve verileri al
                tab_data = get_tabs_content(driver, link)
                
                save_to_json(id,tab_data, link)
            else:
                print(f"{link} daha önce ziyaret edildi, atlanıyor.")
            
        driver.quit()

    else:
        print("Giriş işlemi başarısız.")

    # Bağlantıyı kapat
    cursor.close()
    db.close()