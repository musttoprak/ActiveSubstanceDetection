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

# ÖZET sekmesi için veri işleme
def process_ozet(driver):
    process = {}

    # İlaç adı ve firma adı
    ilaç_adı_firma = driver.find_element(By.CSS_SELECTOR, "span.text-lg.text-medium a").text.strip()
    process["İlaç Adı ve Firma"] = ilaç_adı_firma

    # Barkod numarası
    try:
        barkod = driver.find_element(By.CSS_SELECTOR, "#barkod_img").text.strip()
        process["Barkod"] = barkod
    except:
        process["Barkod"] = "Barkod bulunamadı"

    # Reçete tipi
    reçete_tipi = driver.find_element(By.CSS_SELECTOR, ".row .card-body span").text.strip()
    process["Reçete Tipi"] = reçete_tipi

    # Fiyatları al
    fiyatlar = driver.find_elements(By.CSS_SELECTOR, ".col-md-4 span.pull-right")
    fiyatlar_text = [fiyat.text.strip() for fiyat in fiyatlar]
    if len(fiyatlar_text) >= 4:
        process.update({
            "Perakende Satış Fiyatı": fiyatlar_text[0],
            "Depocu Satış Fiyatı (KDV Dahil)": fiyatlar_text[1],
            "Depocu Satış Fiyatı (KDV Hariç)": fiyatlar_text[2],
            "İmalatçı Satış Fiyatı (KDV Hariç)": fiyatlar_text[3]
        })

    # KDV oranı
    try:
        kdv = driver.find_element(By.XPATH, "//*[contains(text(),'KDV')]").text.strip()
        process["KDV"] = kdv
    except:
        process["KDV"] = "KDV bilgisi bulunamadı"

    # Fiyat tarihi
    try:
        fiyat_tarihi = driver.find_element(By.XPATH, "//*[contains(text(),'Fiyat Tarihi')]").text.strip()
        process["Fiyat Tarihi"] = fiyat_tarihi
    except:
        process["Fiyat Tarihi"] = "Fiyat tarihi bulunamadı"

    return process


# FIYAT HAREKETLERI sekmesi için veri işleme
def process_fiyat(driver):
    process = {}

    # Tablo başlıklarını al
    hareketler_basliklari = driver.find_elements(By.CSS_SELECTOR, ".table th")
    basliklar = [baslik.text.strip() for baslik in hareketler_basliklari]

    # Satırları al
    hareketler_satirlar = driver.find_elements(By.CSS_SELECTOR, ".table tbody tr")
    fiyat_hareketleri = []
    for satir in hareketler_satirlar:
        hareket = {}
        hücreler = satir.find_elements(By.CSS_SELECTOR, "td")
        for i, hücre in enumerate(hücreler):
            if i < len(basliklar):
                hareket[basliklar[i]] = hücre.text.strip()
        fiyat_hareketleri.append(hareket)

    process["Fiyat Hareketleri"] = fiyat_hareketleri
    return process


# ETKIN MADDE sekmesi için veri işleme
def process_etkin_madde(driver):
    process = {}

    # Etkin madde adı ve dozaj bilgisi
    etkin_madde_adı = driver.find_element(By.CSS_SELECTOR, "a[href*='operation=etkin_madde']").text.strip()
    process["Etkin Madde"] = etkin_madde_adı

    dozaj = driver.find_element(By.CSS_SELECTOR, "td.text-right").text.strip()
    process["Dozaj"] = dozaj
    return process


# SUT ÖZET sekmesi için veri işleme
def process_sut_ozet(driver):
    process = {}

    # SGK durumu bilgisi
    try:
        sgk_durumu = driver.find_element(By.CSS_SELECTOR, ".alert-danger .text-danger").text.strip()
        process["SGK Durumu"] = sgk_durumu
    except:
        process["SGK Durumu"] = "SGK bilgisi bulunamadı"
    return process


# EŞDEĞER sekmesi için veri işleme
def process_esdeger(driver):
    process = []

    try:
        ampul_table = driver.find_element(By.CSS_SELECTOR, "span.text-lg.text-primary.text-bold")
        ampul_table = ampul_table.find_element(By.XPATH, "following-sibling::table")
        ampul_rows = ampul_table.find_elements(By.TAG_NAME, "tr")
        for row in ampul_rows:
            cells = row.find_elements(By.TAG_NAME, "td")
            if len(cells) > 0:
                process.append({
                    "Barkod": cells[0].text.strip(),
                    "Firma": cells[1].text.strip(),
                    "İsim": cells[2].text.strip(),
                    "Eşdeğer Kodu": cells[3].text.strip(),
                    "PSF": cells[4].text.strip(),
                    "Kamu Fiyatı": cells[5].text.strip(),
                    "Fiyat Farkı": cells[6].text.strip()
                })
    except:
        process.append({"Error": "Eşdeğer bilgisi alınamadı"})
    
    return process

# Sekme içeriğine göre işleme fonksiyonu çağırma
def process_tab_content(driver, tab_name, content_id):
    processors = {
        "ÖZET": process_ozet,
        "FIYAT HAREKETLERI": process_fiyat,
        "ETKIN MADDE": process_etkin_madde,
        "SUT ÖZET": process_sut_ozet,
        "EŞDEĞER": process_esdeger
    }

    if tab_name in processors:
        return processors[tab_name](driver)
    else:
        return {"Error": f"Unknown tab: {tab_name}"}


# Tüm sekmeleri işleyip veri toplama
def get_tabs_content(driver, link):
    driver.get(link)  # Load the page
    
    # Find all tabs
    tabs = driver.find_elements(By.CSS_SELECTOR, "ul[data-toggle='tabs'] li a")
    tab_data = {}  # Dictionary to store data
    
    # Initialize tab_name with a default value
    tab_name = None

    # Retrieve the product name
    try:
        product_name_element = driver.find_element(By.CSS_SELECTOR, "#isimHeader span[data-name='urun_adi']")
        product_name = product_name_element.text.strip()
        tab_data["Adı"] = product_name
    except Exception as e:
        tab_data["Adı"] = "Ürün adı bulunamadı"
        print(f"Ürün adı alınırken hata oluştu: {e}")

    # Process each tab
    for tab in tabs:
        try:
            if ("display: none" not in tab.get_attribute("style")) and tab.text.strip() != "":
                tab_name = tab.text.strip()  # Get the tab name
                href_value = tab.get_attribute("href")
                content_id = href_value.split("#")[1]  # Extract "tab_anabilgi"

                # Click the tab and wait for content to load
                tab.click()
                time.sleep(1)  # Wait for dynamic content to load
                
                # Process the content
                tab_data[tab_name] = process_tab_content(driver, tab_name, content_id)
        except Exception as e:
            print(f"{tab_name if tab_name else 'Unknown tab'} sekmesi işlenirken hata oluştu: {e}")
            tab_data[tab_name if tab_name else 'Unknown tab'] = {"Error": str(e)}

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
        
        start_index = 7187  # İlk 65 tanesini atlamak için başlangıç noktasını ayarla (0'dan başlar)
        current_index = 0  # Mevcut sırayı takip etmek için sayaç

        # Her link için işlem yap
        for row in rows:
            id, link = row
            
            if link not in visited_links:
                visited_links.add(link)  # Linki ziyaret edilenler listesine ekle
                if current_index < start_index:
                    current_index += 1
                    continue 
                
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