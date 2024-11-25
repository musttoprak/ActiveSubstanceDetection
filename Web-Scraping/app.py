import configparser
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import ElementClickInterceptedException
from selenium.common.exceptions import TimeoutException
import time
import pandas as pd
import json
import os
import re

# Config dosyasını oku
def read_config():
    config = configparser.ConfigParser()
    config.read('config.ini', encoding='utf-8')
    return config

# WebDriver'ı başlat
def start_driver(driver_path):
    options = webdriver.ChromeOptions()
    service = Service(executable_path=driver_path)
    return webdriver.Chrome(service=service, options=options)

def close_cookie_banner(driver):
    try:
        cookie_accept = driver.find_element(By.ID, 'cookiescript_accept')
        cookie_accept.click()
        print("Cookie banner closed successfully.")
    except Exception as e:
        print("Cookie banner couldn't be closed: ", e)
       
# Giriş yap
def login(driver, email, password, url):
    driver.get(url)
    time.sleep(3)
    driver.find_element(By.NAME, 'email').send_keys(email)
    driver.find_element(By.NAME, 'parola').send_keys(password + Keys.RETURN)

# Verileri toplamak için kaydırma yap
def scroll_and_collect_data(driver, scrollable_div_selector):
    data = []
    last_height = driver.execute_script("return document.body.scrollHeight")
    timeout = 10
    start_time = time.time()
    found = False
    scrollable_div = driver.find_element(By.CSS_SELECTOR, scrollable_div_selector)

    while True:
        ul_element = driver.find_element(By.TAG_NAME, 'ul')
        items = ul_element.find_elements(By.TAG_NAME, 'li')

        # Öğeleri topla
        for item in items:
            # Kaydırma işlemi
            driver.execute_script("arguments[0].scrollTop += 1000;", scrollable_div)
            item_text = item.text
            if item_text not in data:
                data.append(item_text)
                if item_text.lower().startswith("dor"):
                    found = True
                
                if(found):
                    try:
                        WebDriverWait(driver, 10).until(EC.element_to_be_clickable(item))
                        item.click()
                        collect_item_data(driver)
                    except TimeoutException:
                        print(f"Öğe tıklanabilir durumda değil, atlanıyor: {item_text}")
                        continue 

        # Sayfayı kaydır
        driver.execute_script("arguments[0].scrollTop += 1000;", scrollable_div)
        time.sleep(1)  # Sayfanın yüklenmesi için bekle

        new_height = driver.execute_script("return arguments[0].scrollHeight;", scrollable_div)
        if new_height == last_height:
            if time.time() - start_time > timeout:
                break
        else:
            start_time = time.time()
        last_height = new_height

        # Yeni öğeler yüklenip yüklenmediğini kontrol et
        if len(items) == len(data):  # Eğer yeni öğe yoksa döngüden çık
            break

    return data

# Belirli bir öğe için verileri topla
def collect_item_data(driver):
    info_div = driver.find_element(By.CSS_SELECTOR, '.col-sm-8.col-md-9.col-lg-10')
    drug_name = info_div.find_element(By.TAG_NAME, 'h3').text
    file_name = f"{drug_name.replace(' ', '_')}.json"  # Boşlukları alt çizgi ile değiştir

    general_info_content = collect_general_info(driver, info_div)
    therapeutic_content = collect_therapeutic_info(driver, info_div)

    save_item_data(file_name, drug_name, general_info_content, therapeutic_content)

def collect_general_info(driver, info_div):
    try:
        # Click on the General Info tab
        general_info_tab = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable(info_div.find_element(By.CSS_SELECTOR, 'a[href="#bilgi"]'))
        )
        general_info_tab.click()

        # Wait for the general info content to be visible
        general_info_content = WebDriverWait(driver, 10).until(
            EC.visibility_of_element_located((By.ID, 'bilgi'))
        )

        # Collect the image link
        image = general_info_content.find_element(By.TAG_NAME, 'img')
        image_src = image.get_attribute('src') if image else None

        # Collect table data
        table_data = {}
        table = general_info_content.find_element(By.TAG_NAME, 'table')
        rows = table.find_elements(By.TAG_NAME, 'tr')
        for row in rows:
            cells = row.find_elements(By.TAG_NAME, 'td')
            if len(cells) == 2:
                key = cells[0].text.strip().replace(':', '')
                value = cells[1].text.strip()
                table_data[key] = value

        
        # Ekstra bilgi bölümlerini toplama
        additional_info = {}
        info_sections = general_info_content.find_elements(By.XPATH, './/h3')
        for section in info_sections:
            section_title = section.text.strip()
            section_content = []
            next_element = section.find_element(By.XPATH, 'following-sibling::*')
            
            # Başka bir başlığa kadar git
            while next_element is not None and next_element.tag_name != 'h3':
                section_content.append(next_element.text.strip())
                # Sonraki elementi güncelle
                try:
                    next_element = next_element.find_element(By.XPATH, 'following-sibling::*')
                except:
                    break  # Eğer element bulunamazsa döngüden çık

            additional_info[section_title] = ' '.join(section_content)

        return {
            'image_src': image_src,
            'table_data': table_data,
            'additional_info': additional_info
        }

    except Exception as e:
        print(f"An error occurred while collecting general info: {e}")
        return None

def collect_therapeutic_info(driver, info_div):
    therapeutic_tab = info_div.find_element(By.CSS_SELECTOR, 'a[href="#urun"]')
    therapeutic_data = []  # Tüm verileri saklamak için liste
    
    try:
        # Elemanın görünür olduğundan emin ol
        WebDriverWait(driver, 10).until(EC.visibility_of(therapeutic_tab))
        therapeutic_tab.click()  # Tıklama işlemi
        
        # Custom select objesini bul
        custom_select = Select(driver.find_element(By.CLASS_NAME, 'custom-select'))
        options = custom_select.options  # Tüm seçenekleri al
        custom_select.select_by_index(len(options) - 1)

        while True:
            # Tablo verilerini al
            therapeutic_table = info_div.find_element(By.ID, 'urun')  # Tablo kısmını bul
            rows = therapeutic_table.find_elements(By.TAG_NAME, 'tr')  # Satırları al
            
            for index, row in enumerate(rows):
                # Başlık satırını atla (index 0)
                if index == 0:
                    continue
                
                columns = row.find_elements(By.TAG_NAME, 'td')  # Her satırdaki hücreleri al
            
                try:
                    product_link = columns[0].find_element(By.TAG_NAME, 'a').get_attribute('href')  # Ürün linkini al
                    product_name = columns[0].text.strip()  # Ürün adını al
                    company_name = columns[1].text.strip()  # Firma adını al
                    
                    # SGK durumunu kontrol et
                    sgk_cell = columns[2].find_element(By.CLASS_NAME, 'badge')  # SGK durumu hücresini al
                    sgk_status = 'Bilinmiyor'  # Varsayılan değer
                    if 'style-success' in sgk_cell.get_attribute('class'):
                        sgk_status = 'SGK Var'
                    elif 'style-danger' in sgk_cell.get_attribute('class'):
                        sgk_status = 'SGK Yok'
                    
                    therapeutic_data.append((product_name, company_name, sgk_status, product_link))  # Veriyi kaydet
                except Exception as e:
                    print(f"Hata: {e} | Satır: {row.text}")

            # Sayfa geçiş butonunu bul
            next_button = driver.find_element(By.CSS_SELECTOR, 'button[aria-label="Next Page"]')

            # Eğer buton "disabled" durumdaysa döngüden çık
            if "disabled" in next_button.get_attribute("outerHTML"):
                break  # Daha fazla sayfa yok
            
            # Buton tıklanabilir olana kadar bekle
            WebDriverWait(driver, 1).until(EC.element_to_be_clickable(next_button))
            next_button.click()  # Sonraki sayfaya geç
            time.sleep(0.5)  # Sayfanın yüklenmesi için bekle
        
    except Exception as e:
        print(f"Click error: {e}")

    return therapeutic_data
    
def sanitize_filename(filename):
    # Dosya adında geçerli olmayan karakterleri temizliyoruz
    return re.sub(r'[\/:*?"<>|]', '', filename)    

# Verileri dosyaya kaydet
def save_item_data(file_name, drug_name, general_info_content, therapeutic_content):
    # Verileri yapılandır
    data_to_save = {
        "İlaç Adı": drug_name,
        "Genel Bilgi": general_info_content,
        "Müstahzarlar": therapeutic_content
    }
    file_name = sanitize_filename(file_name)
    # Dosya yolunu oluştur
    base_file_path = os.path.join('etkin_madde', file_name)
    file_path = base_file_path
    counter = 1

    # Dosya mevcutsa, sonuna "a1", "a2" ekleyerek yeni isim oluştur
    while os.path.exists(file_path + '.json'):  # Dosya uzantısını kontrol et
        file_path = f"{base_file_path[:-5]}_a{counter}"  # Son 5 karakter ".json" olduğu için çıkarıyoruz
        file_path += '.json'  # Yeni dosya adını oluştur
        counter += 1

    # Verileri JSON formatında kaydet
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data_to_save, f, ensure_ascii=False, indent=4)  # Daha okunabilir format için indent kullan
    
    print(f"{file_path} dosyası kaydedildi.")

def clear_directory(directory):
    # Klasördeki tüm dosyaları sil
    for filename in os.listdir(directory):
        file_path = os.path.join(directory, filename)
        try:
            if os.path.isfile(file_path):  # Dosya mı kontrol et
                os.remove(file_path)  # Dosyayı sil
                print(f"{file_path} silindi.")
            elif os.path.isdir(file_path):  # Klasör mü kontrol et
                os.rmdir(file_path)  # Klasörü sil (boşsa)
                print(f"{file_path} klasörü silindi.")
        except Exception as e:
            print(f"Hata: {e}")
    
# Ana fonksiyon
def main():
    config = read_config()
    driver = start_driver(config['DEFAULT']['webdriver_path'])
    
    try:
        #clear_directory('etkin_madde')
        login(driver, config['DEFAULT']['email'], config['DEFAULT']['password'], config['DEFAULT']['url'])
        driver.get(config['DEFAULT']['etkin_madde_url'])
        close_cookie_banner(driver)
        data = scroll_and_collect_data(driver, ".tw-w-full.tw-bg-gray-100.tw-overflow-y-auto")
        
        # Verileri bir dosyaya kaydet
        df = pd.DataFrame(data, columns=['Etkin Madde'])
        df.to_csv('etkin_madde_verileri.csv', index=False)

    finally:
        driver.quit()

if __name__ == "__main__":
    main()
