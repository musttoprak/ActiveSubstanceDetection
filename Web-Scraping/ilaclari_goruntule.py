import json
from bs4 import BeautifulSoup

def process_json_file(file_path):
    """JSON dosyasını işle ve HTML etiketlerinden arındırılmış veriyi döndür."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            data = json.load(file)
        
        clean_data = {}
        
        for tab_name, content in data.items():
            if isinstance(content, str):  # İçerik bir string ise
                soup = BeautifulSoup(content, 'html.parser')
                clean_data[tab_name] = soup.get_text(strip=True)  # HTML'den arındırılmış metni al
            else:
                # Eğer içerik JSON objesi veya listeyse, bu haliyle sakla
                clean_data[tab_name] = content
        
        return clean_data
    except Exception as e:
        print(f"Hata: {e}")
        return None

def save_clean_data_to_file(clean_data, output_file):
    """Temizlenmiş veriyi bir JSON dosyasına kaydet."""
    try:
        with open(output_file, 'w', encoding='utf-8') as file:
            json.dump(clean_data, file, ensure_ascii=False, indent=4)
        print(f"Temizlenmiş veri '{output_file}' dosyasına kaydedildi.")
    except Exception as e:
        print(f"Kaydetme sırasında hata oluştu: {e}")

# Örnek Kullanım
json_file_path = "ilaclar/1-MTA5NTY.json"  # İşlenecek JSON dosyası
output_file_path = "veri_ilaclar/clean_data.json"  # Temizlenmiş veri dosyası

# JSON verisini işle
clean_data = process_json_file(json_file_path)

# İşlenmiş veriyi başka bir JSON dosyasına kaydet
if clean_data:
    save_clean_data_to_file(clean_data, output_file_path)
