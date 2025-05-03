import numpy as np
import pandas as pd
import requests
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
import warnings
from sklearn.exceptions import ConvergenceWarning
import joblib
import flask
from flask import Flask, request, jsonify
import logging
import os
import json
import datetime
from sklearn.model_selection import GridSearchCV
from collections import defaultdict
import seaborn as sns
import matplotlib.pyplot as plt
import random
import time


# Loglama ayarları
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("ilac_oneri_model.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("IlacOneriModel")

# Flask App
app = Flask(__name__)

# API Adresleri (değiştirilmesi gerekebilir)
API_BASE_URL = "http://192.168.1.16:8000/api"  # Laravel API base URL

class IlacOneriModel:
    def __init__(self):
        self.model = None
        self.model_path = "ilac_oneri_model.joblib"
        self.model_metrics = {}
        self.preprocessor = None
        self.etken_madde_encoder = None
        self.hastalik_encoder = None
        self.ilac_lookup = {}
        self.etken_madde_lookup = {}
        self.model_last_trained = None
        self.model_version = "1.0"

    
        self.dataframes = {}
        self.summary = {}
        self.error_report = []
        self.warnings = []
        
        # Modeli yükle (eğer varsa)
        if os.path.exists(self.model_path):
            self.load_model()
        else:
            logger.info("Model bulunamadı. Yeni model eğitilecek.")
            
        # İlaç etki vektörü eşleştirme tablosu
        self.ilac_etki_vektoru = {}
        
        # Hasta özellikleri geçici önbelleği
        self.hasta_ozellikleri_cache = {}
    
    def fetch_data(self):
        """API'den veri çekme - geliştirilmiş loglama ile"""
        logger.info("Veriler API'den çekiliyor...")
        data = {
            "hastalar": [],
            "hastaliklar": [],
            "hasta_hastaliklar": [],
            "ilaclar": [],
            "etken_maddeler": [],
            "ilac_etken_maddeler": [],
            "hasta_ilac_kullanim": []
        }
        
        endpoints = {
            "hastalar": "/hastalar?per_page=5000",
            "hastaliklar": "/hastaliklar?per_page=5000",
            "hasta_hastaliklar": "/hasta-hastaliklar?per_page=5000",
            "ilaclar": "/ilaclar?per_page=5000",
            "etken_maddeler": "/etken-maddeler?per_page=5000",
            "ilac_etken_maddeler": "/ilac-etken-maddeler?per_page=1000",
            "hasta_ilac_kullanim": "/hasta-ilac-kullanim?per_page=5000"
        }
        
        total_records = 0
        
        try:
            # Her endpoint için veri çek
            for key, endpoint in endpoints.items():
                try:
                    #logger.info(f"'{key}' verileri çekiliyor: {API_BASE_URL}{endpoint}")
                    page = 1
                    while True:  # Sayfa bazında veri çekmeye devam et
                        #logger.info(f"Sayfa {page} çekiliyor...")
                        response = requests.get(f"{API_BASE_URL}{endpoint}")
                        
                        # HTTP yanıt kodu kontrol et
                        if response.status_code != 200:
                            logger.error(f"API Hatası: {endpoint} - Durum Kodu: {response.status_code}")
                            logger.error(f"Yanıt İçeriği: {response.text[:200]}...")
                            break
                        
                        # Yanıt içeriğini parçala
                        try:
                            response_json = response.json()
                            #logger.info(f"'{key}' API yanıtı: {type(response_json)} tipinde")
                            
                            # Yanıt yapısını kontrol et 
                            if isinstance(response_json, dict):
                                if 'data' in response_json:
                                    # Laravel API tipik yapısı: {"data": [...]}
                                    if isinstance(response_json['data'], dict) and 'data' in response_json['data']:
                                        # Paginate yapısı: {"data": {"data": [...], "current_page": 1, ...}}
                                        response_data = response_json['data']['data']
                                        total_pages = response_json['data'].get('last_page', 1)
                                        #logger.info(f"Sayfalanmış veri yapısı tespit edildi. Toplam sayfa: {total_pages}")
                                    else:
                                        response_data = response_json['data']
                                        total_pages = 1
                                else:
                                    response_data = []
                                    logger.warning(f"'{key}' için 'data' alanı bulunamadı")
                                    total_pages = 1
                            else:
                                response_data = response_json
                                total_pages = 1
                            
                            # Liste olduğundan emin ol
                            if not isinstance(response_data, list):
                                logger.error(f"'{key}' için veri listesi değil: {type(response_data)}")
                                response_data = []
                                total_pages = 1
                            
                            # Veriyi kaydet
                            data[key].extend(response_data)  # Yeni verileri mevcut veriye ekle
                            
                            # Veri içeriğini logla
                            num_records = len(response_data)
                            total_records += num_records
                            #logger.info(f"'{key}' için {num_records} kayıt alındı. Toplam {total_records} kayıt.")
                            
                            # Sayfanın sonuna gelindi mi kontrol et
                            if page >= total_pages:
                                break
                            else:
                                page += 1  # Sonraki sayfaya geç

                        except ValueError as json_err:
                            logger.error(f"JSON parse hatası ({key}): {json_err}")
                            logger.error(f"Ham yanıt: {response.text[:200]}...")
                
                except Exception as e:
                    logger.error(f"'{key}' verileri çekilirken hata: {e}")
                    import traceback
                    logger.error(traceback.format_exc())
            
            logger.info(f"Veri çekme tamamlandı. Toplam {total_records} kayıt alındı.")
            
            # Her veri kümesinin yapısını özet olarak raporla
            for key, value in data.items():
                record_count = len(value)
                sample = str(value[0])[:100] + "..." if record_count > 0 else "Veri yok"
                #logger.info(f"'{key}': {record_count} kayıt, örnek: {sample}")
            
            return data
        
        except Exception as e:
            logger.error(f"Veri çekme işlemi sırasında genel hata: {e}")
            import traceback
            logger.error(traceback.format_exc())
            raise

    def prepare_data(self, data):
            """Veri hazırlama ve temizleme"""
            logger.info("Veriler hazırlanıyor...")
            
            # Veri çerçevelerini oluştur ve kolon adlarını düzelt
            try:
                # Güvenli DataFrame oluşturma fonksiyonunu kullan
                ilaclar_df = self.safe_dataframe_creation(data["ilaclar"], ["ilac_id", "ilac_adi"])
                etken_maddeler_df = self.safe_dataframe_creation(data["etken_maddeler"], ["etken_madde_id","etken_madde_adi"])
                ilac_etken_df = self.safe_dataframe_creation(data["ilac_etken_maddeler"], ["ilac_id", "etken_madde_id"])
                hastaliklar_df = self.safe_dataframe_creation(data["hastaliklar"], ["hastalik_id", "hastalik_adi","hastalik_kategorisi"])
                hastalar_df = self.safe_dataframe_creation(data["hastalar"], ["hasta_id", "yas", "cinsiyet", "boy", "kilo", "vki"])
                hasta_hastalik_df = self.safe_dataframe_creation(data["hasta_hastaliklar"], ["hasta_hastalik_id", "hasta_id", "hastalik_id"])
                ilac_kullanim_df = self.safe_dataframe_creation(data["hasta_ilac_kullanim"], ["kullanim_id", "hasta_id", "ilac_id"])
    
            except Exception as e:
                logger.error(f"DataFrame oluşturma hatası: {e}")
            
            # Veri eksikliği kontrolü
            if len(ilaclar_df) == 0 or len(hasta_hastalik_df) == 0 or len(ilac_kullanim_df) == 0:
                logger.warning("Yeterli veri yok: ilaclar, hasta-hastalik veya ilac-kullanim verileri eksik")
                # Boş veri döndür
                features = pd.DataFrame()
                target = pd.Series(dtype='float')
                return features, target
            
            # Lookup tabloları oluşturma
            if 'ilac_id' in ilaclar_df.columns and 'ilac_adi' in ilaclar_df.columns:
                self.ilac_lookup = dict(zip(ilaclar_df["ilac_id"], ilaclar_df["ilac_adi"]))
            else:
                self.ilac_lookup = {}
            
            if 'etken_madde_id' in etken_maddeler_df.columns and 'etken_madde_adi' in etken_maddeler_df.columns:
                self.etken_madde_lookup = dict(zip(etken_maddeler_df["etken_madde_id"], etken_maddeler_df["etken_madde_adi"]))
            else:
                self.etken_madde_lookup = {}
            
            # İlaç-etken madde ilişkisi lookup tablosu oluştur
            # Bu tablo, her ilacın etken maddelerini tutacak
            self.ilac_etken_lookup = {}
            
            if 'ilac_id' in ilac_etken_df.columns and 'etken_madde_id' in ilac_etken_df.columns:
                # Her ilacın etken maddelerini bir listeye ekle
                for _, row in ilac_etken_df.iterrows():
                    ilac_id = row['ilac_id']
                    etken_id = row['etken_madde_id']
                    
                    if ilac_id not in self.ilac_etken_lookup:
                        self.ilac_etken_lookup[ilac_id] = []
                    
                    # Etken madde ID'sini ekle
                    self.ilac_etken_lookup[ilac_id].append(etken_id)
            
            logger.info(f"Lookup tabloları oluşturuldu: {len(self.ilac_lookup)} ilaç, {len(self.etken_madde_lookup)} etken madde, {len(self.ilac_etken_lookup)} ilaç-etken madde ilişkisi")
            
            try:
                # Hasta demografik bilgilerini hazırla
                demo_cols = ['hasta_id', 'yas', 'cinsiyet', 'boy', 'kilo', 'vki']
                available_cols = [col for col in demo_cols if col in hastalar_df.columns]
                
                if len(available_cols) > 1:  # En az id ve bir özellik olmalı
                    hastalar_demo = hastalar_df[available_cols].copy()
                    
                    # Cinsiyet encoding
                    if 'cinsiyet' in hastalar_demo.columns:
                        hastalar_demo['cinsiyet_encoded'] = hastalar_demo['cinsiyet'].map(
                            lambda x: 1 if str(x).lower() == 'erkek' else 0
                        )
                    
                    # VKI hesaplama (eğer hesaplanmamışsa)
                    if 'vki' in hastalar_demo.columns and 'boy' in hastalar_demo.columns and 'kilo' in hastalar_demo.columns:
                        vki_mask = hastalar_demo['vki'].isna() & ~hastalar_demo['boy'].isna() & ~hastalar_demo['kilo'].isna()
                        if sum(vki_mask) > 0:
                            hastalar_demo.loc[vki_mask, 'vki'] = hastalar_demo.loc[vki_mask, 'kilo'] / ((hastalar_demo.loc[vki_mask, 'boy'] / 100) ** 2)
                else:
                    hastalar_demo = pd.DataFrame(columns=['hasta_id', 'yas', 'cinsiyet_encoded', 'vki'])
                
                # 1. Kategori sütununu belirle
                if 'hastalik_kategorisi' in hastaliklar_df.columns:
                    category_col = 'hastalik_kategorisi'
                else:
                    # Kategori kolonu yoksa boş bir seri oluştur
                    hastaliklar_df['hastalik_kategorisi'] = 'Bilinmiyor'
                    category_col = 'hastalik_kategorisi'
                

                # Hasta-hastalık eşleştirme
                hasta_hastalik_merged = pd.merge(
                    hasta_hastalik_df,
                    hastaliklar_df, 
                    left_on="hastalik_id",
                    right_on="hastalik_id",
                    suffixes=("", "_hastalik"),
                    how="left"
                )
                        
                # İlaç kullanımlarını ilaç bilgileriyle birleştir
                ilac_kullanim_merged = pd.merge(
                    ilac_kullanim_df,
                    ilaclar_df,
                    left_on="ilac_id",
                    right_on="ilac_id",
                    suffixes=("", "_ilac"),
                    how="left"
                )
                
                # 4. İlaç ve etken madde ilişkilerini oluştur
                if len(ilac_etken_df) > 0 and len(etken_maddeler_df) > 0:
                    # Bu veri varsa birleştir
                    ilac_etken_merged = pd.merge(
                        ilac_etken_df,
                        etken_maddeler_df,
                        left_on="etken_madde_id",
                        right_on="etken_madde_id",
                        suffixes=("", "_etken"),
                        how="left"
                    ) 

                    # İlaç kullanımları ve etken maddeleri birleştir
                    kullanim_etken = pd.merge(
                        ilac_kullanim_merged,
                        ilac_etken_merged,  # Etken maddeleri de dahil et
                        on="ilac_id",
                        how="left"
                    )
                    
                    # `ilac_id` eksikse temizle
                    kullanim_etken = kullanim_etken.dropna(subset=["ilac_id"])
                else:
                    # Eğer ilaç-etken madde bilgisi yoksa, sadece kullanım bilgilerini kopyala
                    kullanim_etken = ilac_kullanim_merged.copy()
                    kullanim_etken["etken_madde_id"] = np.nan  # Etken madde eksikse NaN yap
                
                # 5. Hasta, hastalık ve kullanılan ilaçlar/etken maddeler
                # Verilerde sorun varsa kontrol et
                if len(hasta_hastalik_merged) == 0 or len(kullanim_etken) == 0:
                    logger.warning("Birleştirme sonrası veri kalmadı")
                    features = pd.DataFrame()
                    target = pd.Series(dtype='float')
                    return features, target
                    
                training_data = pd.merge(
                    hasta_hastalik_merged,
                    kullanim_etken,
                    left_on=["hasta_id"],
                    right_on=["hasta_id"],
                    how="left"
                )
                
                # İlac_id eksikse işlemi durdur
                if 'hasta_id' not in training_data.columns or training_data['hasta_id'].isna().all():
                    logger.error("Eğitim verisinde hasta_id eksik")
                    features = pd.DataFrame()
                    target = pd.Series(dtype='float')
                    return features, target
                
                # 6. Hasta demografik bilgileri de ekle (varsa)
                if 'hasta_id' in training_data.columns and 'hasta_id' in hastalar_demo.columns:
                    if not hastalar_demo.empty:
                        training_data = pd.merge(
                            training_data,
                            hastalar_demo,
                            left_on="hasta_id",
                            right_on="hasta_id",
                            how="left",
                            suffixes=("", "_hasta")
                        )
                    else:
                        logger.warning("Hastalar demo verisi boş.")
                else:
                    logger.error("hasta_id sütunu eksik.")
                
                # Veri var mı kontrol et
                if len(training_data) == 0:
                    logger.warning("Eğitim için veri yok")
                    features = pd.DataFrame()
                    target = pd.Series(dtype='float')
                    return features, target
                
                # Özellik seçimi - temel özellikler
                feature_cols = ["hasta_id", "hastalik_id"]
                
                # Kategori (varsa)
                if category_col in training_data.columns:
                    feature_cols.append(category_col)
                
                # Etken madde özelliği (varsa)
                if "etken_madde_id" in training_data.columns and not training_data["etken_madde_id"].isna().all():
                    feature_cols.append("etken_madde_id")
                
                # Demografik özellikler (varsa)
                for col in ['yas', 'cinsiyet_encoded', 'vki']:
                    if col in training_data.columns and not training_data[col].isna().all():
                        feature_cols.append(col)
                
                # Hastalık şiddeti (varsa)
                if 'siddet' in training_data.columns and not training_data['siddet'].isna().all():
                    feature_cols.append('siddet')
                
                # En az hasta_id ve hastalik_id olmalı
                if len(feature_cols) < 3:
                    logger.warning(f"Yeterli özellik yok: {feature_cols}")
                    features = pd.DataFrame()
                    target = pd.Series(dtype='float')
                    return features, target
                
                # Özellikleri ve hedef değişkeni seç
                features = training_data[feature_cols].copy()
                target = training_data["ilac_id"]
                
                # NaN değerleri doldur
                for col in features.columns:
                    if features[col].dtype == np.float64 or features[col].dtype == np.float32:
                        features[col] = features[col].fillna(features[col].median())
                    elif features[col].dtype == np.int64 or features[col].dtype == np.int32:
                        features[col] = features[col].fillna(features[col].median())
                    else:
                        features[col] = features[col].fillna('Bilinmiyor')
                
                logger.info(f"Veri hazırlama tamamlandı. {len(features)} kayıt işlendi. Kullanılan özellikler: {feature_cols}")
                return features, target
                
            except Exception as e:
                logger.error(f"Veri hazırlama sırasında hata: {e}")
                import traceback
                logger.error(traceback.format_exc())
                # Boş verilerle devam et
                features = pd.DataFrame()
                target = pd.Series(dtype='float')
                return features, target
        
    def safe_dataframe_creation(self, data_list, required_columns=[]):
        """
        Güvenli DataFrame oluşturma - boş veya eksik veriler için önlemler alır
        
        Args:
            data_list (list): Veri listesi (dict'lerin listesi olmalı)
            required_columns (list): DataFrame'de bulunması gereken sütunlar
            
        Returns:
            pandas.DataFrame: Oluşturulan DataFrame
        """
        # Fonksiyon girişini logla
        #logger.info(f"DataFrame oluşturuluyor: {len(data_list) if isinstance(data_list, list) else 'Liste değil'} öğe, gerekli sütunlar: {required_columns}")
        
        # Veri listesi yoksa veya boşsa, boş DataFrame döndür
        if not data_list or not isinstance(data_list, list) or len(data_list) == 0:
            logger.warning(f"Boş veya geçersiz veri listesi. Boş DataFrame döndürülüyor.")
            return pd.DataFrame(columns=required_columns)
        
        # Geçerli dict öğelerini filtreleme
        valid_items = []
        invalid_count = 0
        
        for i, item in enumerate(data_list):
            if isinstance(item, dict):
                valid_items.append(item)
            else:
                invalid_count += 1
                if invalid_count <= 3:  # Sadece ilk 3 geçersiz öğeyi logla
                    logger.warning(f"Geçersiz öğe #{i}: {type(item)} - {str(item)[:50]}")
        
        if invalid_count > 0:
            logger.warning(f"Toplam {invalid_count} geçersiz öğe atlandı")
        
        if len(valid_items) == 0:
            logger.error("Geçerli öğe kalmadı. Boş DataFrame döndürülüyor.")
            return pd.DataFrame(columns=required_columns)
        
        # Tüm öğelerin aynı yapıda olduğundan emin ol
        # İlk öğeyi referans olarak al
        keys_from_first_item = set(valid_items[0].keys())
        
        # Tüm öğelerde ortak olan anahtarları bul
        common_keys = keys_from_first_item.copy()
        for item in valid_items[1:]:
            item_keys = set(item.keys())
            common_keys = common_keys.intersection(item_keys)
        
        # Eksik anahtarları tespit et
        all_keys = set()
        for item in valid_items:
            all_keys.update(item.keys())
        
        missing_keys_count = {key: 0 for key in all_keys}
        for item in valid_items:
            for key in all_keys:
                if key not in item:
                    missing_keys_count[key] += 1
        
        # Eksik anahtarları logla
        for key, count in missing_keys_count.items():
            if count > 0:
                logger.info(f"'{key}' anahtarı {count}/{len(valid_items)} öğede eksik")
        
        # Ortak anahtarları logla
        #logger.info(f"Tüm öğelerde ortak olan {len(common_keys)} anahtar: {common_keys}")
        
        # Tüm anahtar değer çiftlerinin sabit uzunlukta olduğunu garantile
        standardized_data = []
        
        for item in valid_items:
            new_item = {}
            for key in all_keys:
                new_item[key] = item.get(key, None)
            standardized_data.append(new_item)
        
        try:
            # DataFrame oluştur
            df = pd.DataFrame(standardized_data)
            
            # Gerekli sütunların var olduğundan emin ol
            for col in required_columns:
                if col not in df.columns:
                    logger.warning(f"Gerekli sütun '{col}' veride yok, None değerleriyle ekleniyor")
                    df[col] = None
                    
            logger.info(f"Gerekli kolonlar: {required_columns}")
            
            # Sadece gerekli kolonları tut, geri kalanları sil
            df_cleaned = df[required_columns]
            #logger.info(f"Yalnızca gerekli kolonlar kaldı: {df_cleaned.columns.tolist()}")
            
            # NaN değerleri hakkında bilgi
            na_counts = df_cleaned.isna().sum()
            na_cols = [f"{col}: {count}" for col, count in na_counts.items() if count > 0]
            if na_cols:
                logger.info(f"NaN değerleri içeren sütunlar: {', '.join(na_cols)}")   

            return df_cleaned
      
        except Exception as e:
            logger.error(f"DataFrame oluşturma hatası: {e}")
            import traceback
            logger.error(traceback.format_exc())
            
            # Hata detaylarını incelemek için veri örneği
            if standardized_data:
                logger.error(f"İlk veri örneği: {standardized_data[0]}")
            
            # Boş DataFrame döndür
            return pd.DataFrame(columns=required_columns)


    def analiz_et(self, features, target, data=None):
        """
        Model eğitimi öncesinde prepare_data'dan dönen verileri analiz eder
        
        Args:
            features (pd.DataFrame): Özellik veri çerçevesi
            target (pd.Series): Hedef değişken
            data (dict): Orijinal veri sözlüğü (opsiyonel)
        """
        print("=" * 80)
        print("İLAÇ ÖNERİ SİSTEMİ - VERİ ANALİZ RAPORU")
        print("=" * 80)
        
        # 1. Veri boyutları
        print("\n1. VERİ BOYUTLARI")
        print(f"• Özellik matrisi boyutu: {features.shape[0]} satır x {features.shape[1]} sütun")
        print(f"• Hedef değişken boyutu: {len(target)} satır")
        
        if features.shape[0] == 0 or len(target) == 0:
            print("\n⚠️ UYARI: Veri seti boş. Eğitim yapılamaz!")
            return
        
        # 2. Özellik bilgileri
        print("\n2. ÖZELLİK BİLGİLERİ")
        print(f"• Kullanılan özellikler ({features.shape[1]}): {', '.join(features.columns)}")
        
        # 3. Veri türleri
        print("\n3. VERİ TÜRLERİ")
        for col in features.columns:
            print(f"• {col}: {features[col].dtype}")
        
        # 4. Eksik değer analizi
        print("\n4. EKSİK DEĞER ANALİZİ")
        missing = features.isnull().sum()
        if missing.sum() > 0:
            print("⚠️ Aşağıdaki sütunlarda eksik değerler var:")
            for col, count in missing[missing > 0].items():
                print(f"  • {col}: {count} eksik değer ({count/len(features)*100:.1f}%)")
        else:
            print("• Hiçbir sütunda eksik değer yok (veya NaN değerler doldurulmuş)")
        
        # 5. Kategorik değişkenler
        categorical_cols = features.select_dtypes(include=['object', 'category']).columns
        print("\n5. KATEGORİK DEĞİŞKENLER")
        if len(categorical_cols) > 0:
            for col in categorical_cols:
                unique_vals = features[col].nunique()
                print(f"• {col}: {unique_vals} benzersiz değer")
                
                # En yaygın kategorileri göster (en fazla 5)
                top_values = features[col].value_counts().head(5)
                print("  En yaygın değerler:")
                for val, count in top_values.items():
                    print(f"    - {val}: {count} ({count/len(features)*100:.1f}%)")
        else:
            print("• Kategorik değişken yok")
        
        # 6. Sayısal değişkenler
        numeric_cols = features.select_dtypes(include=['int64', 'float64']).columns
        print("\n6. SAYISAL DEĞİŞKENLER")
        if len(numeric_cols) > 0:
            for col in numeric_cols:
                stats = features[col].describe()
                print(f"• {col}:")
                print(f"  - Min: {stats['min']:.2f}, Max: {stats['max']:.2f}")
                print(f"  - Ortalama: {stats['mean']:.2f}, Medyan: {stats['50%']:.2f}")
                print(f"  - Standart sapma: {stats['std']:.2f}")
        else:
            print("• Sayısal değişken yok")
        
        # 7. Hedef değişken analizi
        print("\n7. HEDEF DEĞİŞKEN ANALİZİ")
        print(f"• Hedef değişken türü: {target.dtype}")
        unique_targets = target.nunique()
        print(f"• Benzersiz hedef değer sayısı: {unique_targets}")
        
        # İlaç ID'lerine göre dağılımı göster
        if unique_targets <= 20:
            # Az sayıda benzersiz değer varsa hepsini göster
            target_counts = target.value_counts()
            print("\n• İlaç sınıflarının dağılımı:")
            for val, count in target_counts.items():
                print(f"  - İlaç ID {val}: {count} ({count/len(target)*100:.1f}%)")
        else:
            # Çok fazla benzersiz değer varsa sadece en popüler 10 tanesini göster
            top_targets = target.value_counts().head(10)
            print("\n• En yaygın 10 ilaç sınıfı:")
            for val, count in top_targets.items():
                print(f"  - İlaç ID {val}: {count} ({count/len(target)*100:.1f}%)")
            
            # Dengesiz veri seti olup olmadığını kontrol et
            imbalance_ratio = target.value_counts().iloc[0] / target.value_counts().iloc[-1]
            if imbalance_ratio > 10:
                print(f"\n⚠️ UYARI: Veri seti oldukça dengesiz! En yaygın sınıf / en az görülen sınıf oranı: {imbalance_ratio:.1f}")
        
        # 8. Korelasyon ve İlişkiler
        print("\n8. KATEGORİK-HEDEFİN İLİŞKİSİ")
        for col in categorical_cols:
            target_by_category = features.groupby(col)[features.columns[0]].count()
            n_categories = len(target_by_category)
            print(f"• {col} - {n_categories} kategori için hedef dağılımı:")
            
            # Her kategori için en popüler hedef değeri bul (en fazla 5 kategori göster)
            if n_categories <= 5:
                show_categories = features[col].unique()
            else:
                # Sadece en yaygın 5 kategoriyi göster
                show_categories = features[col].value_counts().head(5).index
            
            for category in show_categories:
                sub_targets = target[features[col] == category].value_counts().head(3)
                if len(sub_targets) > 0:
                    top_target = sub_targets.index[0]
                    top_count = sub_targets.values[0]
                    total = len(target[features[col] == category])
                    print(f"  - {category} için en yaygın: İlaç ID {top_target} ({top_count}/{total}, {top_count/total*100:.1f}%)")
        
        # 9. Veri kalitesi uyarıları
        print("\n9. VERİ KALİTESİ UYARILARI")
        warnings = []
        
        # Veri boyutu kontrolleri
        if features.shape[0] < 100:
            warnings.append(f"⚠️ Veri seti çok küçük: Sadece {features.shape[0]} örnek var. Model performansı sınırlı olabilir.")
        
        # Eksik değer kontrolleri
        high_missing_cols = [col for col, count in missing.items() if count/len(features) > 0.1]
        if high_missing_cols:
            warnings.append(f"⚠️ Bazı sütunlarda önemli miktarda (%10'dan fazla) eksik değer var: {', '.join(high_missing_cols)}")
        
        # Hedef değişken kontrolleri
        if unique_targets < 5:
            warnings.append(f"⚠️ Hedef değişkende sadece {unique_targets} benzersiz değer var. Daha fazla veri gerekebilir.")
        
        if not warnings:
            print("• Önemli bir veri kalitesi sorunu tespit edilmedi.")
        else:
            for warning in warnings:
                print(warning)
        
        # 10. Örnekler
        print("\n10. VERİ ÖRNEKLERİ")
        print("\n• Özellik matrisi (ilk 5 satır):")
        print(features.head(5).to_string())
        print("\n• Hedef değişken (ilk 5 değer):")
        print(target.head(5).to_string())
        
        print("\n" + "=" * 80)
        print("ANALİZ TAMAMLANDI")
        print("=" * 80)

    def analyze_bilinmiyor(self, features, target):
        """
        'Bilinmiyor' değerlerini analiz eder
        
        Args:
            features (pd.DataFrame): Özellik matrisi
            target (pd.Series): Hedef değişken
        """
        print("\n" + "=" * 60)
        print("'BİLİNMİYOR' DEĞERİ ANALİZİ")
        print("=" * 60)
        
        # 1. Kategorik sütunlarda 'Bilinmiyor' değerini ara
        categorical_cols = features.select_dtypes(include=['object', 'category']).columns
        
        if len(categorical_cols) == 0:
            print("• Kategorik sütun bulunamadı, 'Bilinmiyor' değeri analizi yapılamadı.")
            return
        
        bilinmiyor_columns = {}
        
        for col in categorical_cols:
            if features[col].astype(str).str.contains('Bilinmiyor', case=False).any():
                # 'Bilinmiyor' içeren değerlerin sayısını bul
                bilinmiyor_count = features[col].astype(str).str.contains('Bilinmiyor', case=False).sum()
                bilinmiyor_pct = bilinmiyor_count / len(features) * 100
                bilinmiyor_columns[col] = (bilinmiyor_count, bilinmiyor_pct)
        
        if bilinmiyor_columns:
            print(f"• {len(bilinmiyor_columns)} sütunda 'Bilinmiyor' değeri bulundu:")
            for col, (count, pct) in bilinmiyor_columns.items():
                print(f"  - {col}: {count} değer ({pct:.1f}%)")
                
                # Bilinmiyor değerli satırlardan örnek göster
                bilinmiyor_examples = features[features[col].astype(str).str.contains('Bilinmiyor', case=False)].head(3)
                if not bilinmiyor_examples.empty:
                    print(f"    Örnek satırlar (en fazla 3):")
                    for idx, row in bilinmiyor_examples.iterrows():
                        print(f"    * Satır {idx}: {dict(row)}")
        else:
            print("• Hiçbir sütunda 'Bilinmiyor' değeri bulunamadı.")
        
        # 2. Özellik verisi analizi (NaN değerler dolumu?)
        had_nan = False
        for col in features.columns:
            # NaN değer var mı kontrol et (doldurulmadan önce)
            col_null_count = features[col].isnull().sum()
            if col_null_count > 0:
                had_nan = True
                print(f"\n• {col} sütununda {col_null_count} NaN değer var idi.")
                print("  Bu değerler muhtemelen dolduruldu. Doldurma stratejisi:")
                
                # Veri türüne göre doldurma stratejisini tahmin et
                if features[col].dtype in ['int64', 'float64']:
                    print("  - Sayısal değişken: Muhtemelen medyan ile dolduruldu")
                else:
                    print("  - Kategorik değişken: Muhtemelen 'Bilinmiyor' ile dolduruldu")
                    
        if not had_nan:
            print("\n• Orijinal veride NaN değerler tespit edilmedi veya log edilmedi.")
        
        # 3. İlac verilerinde 'Bilinmiyor' analizi
        print("\n• İlgili kod parçacığı:")
        print("""
        # NaN değerleri doldur
        for col in features.columns:
            if features[col].dtype == np.float64 or features[col].dtype == np.float32:
                features[col] = features[col].fillna(features[col].median())
            elif features[col].dtype == np.int64 or features[col].dtype == np.int32:
                features[col] = features[col].fillna(features[col].median())
            else:
                features[col] = features[col].fillna('Bilinmiyor')
        """)
        
        print("\n• Sonuç: Kategorik değişkenlerdeki eksik değerler 'Bilinmiyor' olarak doldurulmuş.")
        
        # 4. Bilinmiyor değerlerinin hedef değişken üzerindeki etkisi
        if bilinmiyor_columns:
            print("\n• 'Bilinmiyor' değerlerinin hedef değişken üzerindeki etkisi:")
            
            for col, (count, pct) in bilinmiyor_columns.items():
                # Bilinmiyor değeri olan ve olmayan satırlar için hedef değişken dağılımını karşılaştır
                bilinmiyor_mask = features[col].astype(str).str.contains('Bilinmiyor', case=False)
                
                # Bilinmiyor değeri olan satırlar için hedef değişken dağılımı
                target_with_bilinmiyor = target[bilinmiyor_mask].value_counts().head(3)
                
                # Bilinmiyor değeri olmayan satırlar için hedef değişken dağılımı
                target_without_bilinmiyor = target[~bilinmiyor_mask].value_counts().head(3)
                
                print(f"\n  > {col} sütunu için:")
                
                if not target_with_bilinmiyor.empty:
                    print(f"    - 'Bilinmiyor' değeri olan satırlar için en yaygın hedef değerler:")
                    for val, cnt in target_with_bilinmiyor.items():
                        print(f"      * İlaç ID {val}: {cnt} ({cnt/len(target[bilinmiyor_mask])*100:.1f}%)")
                
                if not target_without_bilinmiyor.empty:
                    print(f"    - 'Bilinmiyor' değeri olmayan satırlar için en yaygın hedef değerler:")
                    for val, cnt in target_without_bilinmiyor.items():
                        print(f"      * İlaç ID {val}: {cnt} ({cnt/len(target[~bilinmiyor_mask])*100:.1f}%)")
        
        # 5. Öneriler
        print("\n• ÖNERİLER:")
        if bilinmiyor_columns:
            print("  1. 'Bilinmiyor' değerleri yerine daha iyi doldurma stratejileri kullanabilirsiniz:")
            print("     - Sayısal değişkenler için: Ortalama, medyan, veya KNN tabanlı doldurma")
            print("     - Kategorik değişkenler için: En sık değer veya tahmine dayalı doldurma")
            print("  2. Eksik verilerin neden kaynaklandığını araştırın ve veri toplama sürecini iyileştirin")
            print("  3. Eksik verilerin fazla olduğu özellikleri modelden çıkarmayı veya farklı bir şekilde ele almayı düşünün")
        else:
            print("  • Veri setinizde 'Bilinmiyor' değerleri tespit edilmedi. İyi iş!")
        
        print("=" * 60)

    # Veri analizi fonksiyonları
    def analyze_data_distribution(df, column, title):
        """Bir sütunun değer dağılımını analiz eder ve görselleştirir"""
        plt.figure(figsize=(10, 6))
        value_counts = df[column].value_counts()
        
        if len(value_counts) > 20:
            # Çok fazla benzersiz değer varsa, ilk 20'sini göster
            value_counts = value_counts.head(20)
            plt.title(f"{title} (İlk 20 değer)")
        else:
            plt.title(title)
        
        sns.barplot(x=value_counts.index, y=value_counts.values)
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.show()
        
        # İstatistikler
        print(f"Benzersiz değer sayısı: {df[column].nunique()}")
        print(f"En yaygın 5 değer ve sayıları:\n{value_counts.head(5)}")
        
    def analyze_relationships(df1, df2, key, title):
        """İki veri çerçevesi arasındaki ilişkileri analiz eder"""
        merged = pd.merge(df1, df2, on=key, how='inner')
        relationship_counts = merged.groupby(key).size().reset_index(name='count')
        
        plt.figure(figsize=(12, 6))
        plt.title(title)
        plt.hist(relationship_counts['count'], bins=30)
        plt.xlabel('İlişki Sayısı')
        plt.ylabel('Frekans')
        plt.show()
        
        print(f"Ortalama ilişki sayısı: {relationship_counts['count'].mean():.2f}")
        print(f"Maksimum ilişki sayısı: {relationship_counts['count'].max()}")
        print(f"İlişki dağılımı:\n{relationship_counts['count'].describe()}")

    # Eksik veriler için analiz
    def analyze_missing_data(df, title):
        """Veri çerçevesindeki eksik değerleri analiz eder"""
        missing = df.isnull().sum()
        missing_percent = 100 * missing / len(df)
        missing_data = pd.concat([missing, missing_percent], axis=1)
        missing_data.columns = ['Eksik Değer Sayısı', 'Eksik Değer Yüzdesi']
        missing_data = missing_data[missing_data['Eksik Değer Sayısı'] > 0].sort_values('Eksik Değer Yüzdesi', ascending=False)
        
        plt.figure(figsize=(10, 6))
        plt.title(f"{title} - Eksik Değer Analizi")
        sns.barplot(x=missing_data.index, y=missing_data['Eksik Değer Yüzdesi'])
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.show()
        
        return missing_data

    def train_model(self, force_retrain=False):
        """Model eğitimi"""
        if self.model is not None and not force_retrain:
            current_time = datetime.datetime.now()
            last_trained = self.model_last_trained or datetime.datetime.min
            
            # Eğer model son 24 saat içinde eğitilmişse tekrar eğitme
            if (current_time - last_trained).total_seconds() < 86400:  # 24 saat = 86400 saniye
                logger.info("Model zaten son 24 saat içinde eğitilmiş. Eğitim atlanıyor.")
                return self.get_model_performance()
        
        logger.info("Model eğitimi başlatılıyor...")
        
        try:
            # Verileri çek
            data = self.fetch_data()
            
            # Verileri hazırla
            features, target = self.prepare_data(data)

            self.analiz_et(features, target, data)
            self.analyze_bilinmiyor(features, target)

            
            # Veri yoksa erken çık
            if len(features) == 0 or len(target) == 0:
                logger.error("Eğitim için yeterli veri bulunamadı.")
                return None, None, None, None
            
            # Kategorik ve sayısal özellikleri belirle
            categorical_features = []
            numerical_features = []
            
            # Her özelliğin türünü belirle
            for column in features.columns:
                if column == 'hasta_id':
                    continue  # hasta_id'yi özellik olarak kullanma
                
                # Veri türüne göre kategorik/sayısal olarak sınıflandır
                if features[column].dtype == object or len(features[column].unique()) < 10:
                    categorical_features.append(column)
                else:
                    numerical_features.append(column)
            
            logger.info(f"Kategorik özellikler: {categorical_features}")
            logger.info(f"Sayısal özellikler: {numerical_features}")
            
            # Kolon bazında veri dönüşümleri için preprocessor oluştur
            categorical_transformer = OneHotEncoder(handle_unknown='ignore')
            numerical_transformer = StandardScaler()
            
            warnings.filterwarnings("ignore", category=ConvergenceWarning)
            warnings.filterwarnings("ignore", category=UserWarning)
            
            # ColumnTransformer kullanarak kategorik ve sayısal değerlerin dönüşümünü tanımla
            preprocessor = ColumnTransformer(
                transformers=[
                    ("cat", categorical_transformer, categorical_features),
                    ("num", numerical_transformer, numerical_features)
                ],
                remainder="drop"  # hasta_id gibi diğer sütunları düşür
            )
            
            # Veriyi eğitim ve test olarak böl
            X_train, X_test, y_train, y_test = train_test_split(features, target, test_size=0.2, random_state=42)
            logger.info(f"Veri bölündü: X-Eğitim {X_train.shape[0]} kayıt, Test {X_test.shape[0]} kayıt")
            logger.info(f"Veri bölündü: Y-Eğitim {y_train.shape[0]} kayıt, Test {y_test.shape[0]} kayıt")
            
            # GridSearch için hiperparametre aralıkları
            param_grid = {
                'classifier__n_estimators': [100, 200, 300],
                'classifier__max_depth': [10, 20, 30, None],
                'classifier__min_samples_split': [2, 5, 10],
                'classifier__min_samples_leaf': [1, 2, 4],
                'classifier__max_features': ['sqrt', 'log2', None]
            }
            
            # Model pipeline'ı
            pipeline = Pipeline([
                ("preprocessor", preprocessor),
                ("classifier", RandomForestClassifier(random_state=42, class_weight='balanced'))
            ])
            
            # GridSearch ile en iyi modeli bul (yeterli veri varsa)
            if len(X_train) > 100:
                logger.info("GridSearch ile hiperparametre optimizasyonu yapılıyor...")
                
                # Veri miktarına göre çapraz doğrulama (cv) değerini ayarla
                cv = 5 if len(X_train) > 500 else 3
                
                grid_search = GridSearchCV(
                    pipeline, 
                    param_grid, 
                    cv=cv, 
                    scoring='f1_weighted',
                    n_jobs=-1
                )
                
                grid_search.fit(X_train, y_train)
                best_pipeline = grid_search.best_estimator_
                logger.info(f"En iyi parametreler: {grid_search.best_params_}")
            else:
                # Veri azsa varsayılan parametrelerle eğit
                logger.info("Veri az olduğu için hiperparametre optimizasyonu atlandı.")
                best_pipeline = pipeline
                best_pipeline.fit(X_train, y_train)
            
            # Model performansını değerlendir
            y_pred = best_pipeline.predict(X_test)
              
            # İlac_id değerleri çok fazla olabilir, bu nedenle average='weighted' kullanıyoruz
            try:
                accuracy = accuracy_score(y_test, y_pred)
                precision = precision_score(y_test, y_pred, average='weighted', zero_division=0)
                recall = recall_score(y_test, y_pred, average='weighted', zero_division=0)
                f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)
            except Exception as e:
                logger.warning(f"Metrik hesaplama hatası: {e}")
                precision, recall, f1 = 0, 0, 0
            
            logger.info(f"Model eğitimi tamamlandı.")
            logger.info(f"Accuracy: {accuracy:.4f}, Precision: {precision:.4f}, Recall: {recall:.4f}, F1: {f1:.4f}")
            
            # train_model fonksiyonunda şu değişikliği yapın:
            if hasattr(best_pipeline.named_steps['classifier'], 'feature_importances_'):
                importances = best_pipeline.named_steps['classifier'].feature_importances_
                
                # Dönüştürülmüş özellik isimlerini almak için
                preprocessor = best_pipeline.named_steps['preprocessor']
                
                # Yeni kod bloğu
                try:
                    # Özellik isimlerini al
                    feature_names = []
                    for name, transformer, columns in preprocessor.transformers_:
                        if hasattr(transformer, 'get_feature_names_out') and name != 'remainder':
                            # Dönüştürülmüş isimleri al
                            if len(columns) > 0:  # Boş değilse
                                try:
                                    transformed_names = transformer.get_feature_names_out(input_features=columns)
                                    feature_names.extend(transformed_names)
                                except:
                                    # Dönüştürme başarısız olursa direkt kolon isimlerini kullan
                                    feature_names.extend(columns)
                        elif name != 'remainder':
                            # StandardScaler için direkt kolon isimlerini kullan
                            feature_names.extend(columns)
                    
                    if len(feature_names) == len(importances):
                        # Özellik önem derecelerini sırala
                        sorted_idx = importances.argsort()[::-1]
                        sorted_features = [(feature_names[i], importances[i]) for i in sorted_idx]
                    else:
                        logger.warning(f"Özellik isimleri ({len(feature_names)}) ve önem dereceleri ({len(importances)}) boyutları uyuşmuyor")
                        logger.warning(f"Özellik isimleri {feature_names} önem dereceleri {importances}")

                except Exception as e:
                    logger.error(f"Özellik önem dereceleri hesaplanırken hata: {e}")

            # Etken madde ve ilaç ilişkilerini hazırla (tahmin için kullanılacak)
            self.prepare_etken_madde_vectors(data)
            
            # Modeli kaydet
            self.model = best_pipeline
            self.preprocessor = preprocessor
            self.model_last_trained = datetime.datetime.now()
            
            # Özel encoderları sakla (prediction için kullanılacak)
            self.etken_madde_encoder = categorical_transformer
            self.hastalik_encoder = categorical_transformer
            
            # Model metriklerini sakla
            self.model_metrics = {
                'accuracy': accuracy,
                'precision': precision,
                'recall': recall,
                'f1': f1,
                'trained_on': datetime.datetime.now().isoformat(),
                'samples_count': len(features)
            }
            
            self.save_model()
            return accuracy, precision, recall, f1
            
        except Exception as e:
            logger.error(f"Model eğitimi sırasında hata: {e}")
            import traceback
            logger.error(f"Hata ayrıntıları: {traceback.format_exc()}")
            return None, None, None, None

    def get_model_performance(self):
        """
        Mevcut modelin performans metriklerini döndür
        
        Returns:
            tuple: (accuracy, precision, recall, f1) değerleri, eğer metrikler yoksa (None, None, None, None)
        """
        if not hasattr(self, 'model_metrics') or self.model_metrics is None: 
            logger.warning("Model metrikleri bulunamadı")
            return None, None, None, None
        
        logger.info("Model performansı talep edildi")
        logger.info(f"Son eğitim: {self.model_metrics.get('trained_on', 'Bilinmiyor')}")
        logger.info(f"Örnek sayısı: {self.model_metrics.get('samples_count', 'Bilinmiyor')}")
        
        accuracy = self.model_metrics.get('accuracy')
        precision = self.model_metrics.get('precision')
        recall = self.model_metrics.get('recall')
        f1 = self.model_metrics.get('f1')
        
        logger.info(f"Mevcut metrikler - Accuracy: {accuracy if accuracy is not None else 'None'}, "
            f"Precision: {precision if precision is not None else 'None'}, "
            f"Recall: {recall if recall is not None else 'None'}, "
            f"F1: {f1 if f1 is not None else 'None'}")
        
        return accuracy, precision, recall, f1

    def prepare_etken_madde_vectors(self, data):
        """
        Her ilaç için etken madde vektörü oluşturur. Bu vektörler tahmin sırasında
        etken madde uyumluluğu hesaplamak için kullanılır.
        
        Args:
            data (dict): API'den çekilen veri sözlükleri
        """
        try:
            logger.info("İlaç etken madde vektörleri hazırlanıyor...")
            
            # İlaç-etken madde ilişkilerini DataFrame'e dönüştür
            ilac_etken_df = self.safe_dataframe_creation(data["ilac_etken_maddeler"], ["ilac_id", "etken_madde_id"])
            
            # İlişkiler mevcut değilse işlemi sonlandır
            if len(ilac_etken_df) == 0:
                logger.warning("İlaç-etken madde ilişkisi bulunamadı")
                self.ilac_etki_vektoru = {}
                return
            
            # İlac_id ve etken_madde_id sütunlarını kontrol et
            if 'ilac_id' not in ilac_etken_df.columns or 'etken_madde_id' not in ilac_etken_df.columns:
                missing_cols = []
                if 'ilac_id' not in ilac_etken_df.columns:
                    missing_cols.append('ilac_id')
                if 'etken_madde_id' not in ilac_etken_df.columns:
                    missing_cols.append('etken_madde_id')
                
                logger.error(f"İlaç-etken madde ilişkilerinde gerekli sütunlar eksik: {missing_cols}")
                logger.info(f"Mevcut sütunlar: {ilac_etken_df.columns.tolist()}")
                self.ilac_etki_vektoru = {}
                return
            
            # NaN değerleri olan satırları filtrele
            ilac_etken_df = ilac_etken_df.dropna(subset=['ilac_id', 'etken_madde_id'])
            
            # Her ilaç için etken madde listesi oluştur
            ilac_etken_dict = defaultdict(list)
            
            for _, row in ilac_etken_df.iterrows():
                ilac_id = row.get('ilac_id')
                etken_madde_id = row.get('etken_madde_id')
                
                # ID'leri integer olarak sakla
                try:
                    ilac_id = int(ilac_id)
                    etken_madde_id = int(etken_madde_id)
                    ilac_etken_dict[ilac_id].append(etken_madde_id)
                except (ValueError, TypeError):
                    logger.warning(f"Geçersiz ID değerleri: ilac_id={ilac_id}, etken_madde_id={etken_madde_id}")
                    continue
            
            # Vektör tablosunu güncelle
            self.ilac_etki_vektoru = dict(ilac_etken_dict)
            
            # Sonuçları logla
            logger.info(f"{len(self.ilac_etki_vektoru)} ilaç için etken madde vektörleri oluşturuldu")
            
            # Örnek vektörleri logla (ilk 5 ilaç)
            sample_count = min(5, len(self.ilac_etki_vektoru))
            if sample_count > 0:
                sample_ilacs = list(self.ilac_etki_vektoru.keys())[:sample_count]
                for ilac_id in sample_ilacs:
                    etken_madde_ids = self.ilac_etki_vektoru[ilac_id]
                    ilac_adi = self.ilac_lookup.get(ilac_id, f"İlaç {ilac_id}")
                    logger.info(f"Örnek: {ilac_adi} (ID: {ilac_id}) - {len(etken_madde_ids)} etken madde içerir: {etken_madde_ids}")
        
        except Exception as e:
            logger.error(f"Etken madde vektörlerini hazırlarken hata: {e}")
            import traceback
            logger.error(traceback.format_exc())
            self.ilac_etki_vektoru = {}  

    def get_hasta_demografik_bilgileri(self, hasta_id):
        """
        Hasta demografik bilgilerini API'den çek veya önbellekten al
        
        Args:
            hasta_id (int): Hasta ID'si
            
        Returns:
            dict: Demografik bilgiler içeren sözlük
        """
        # Eğer önbellekte varsa oradan al
        if hasta_id in self.hasta_ozellikleri_cache:
            logger.info(f"Hasta {hasta_id} demografik bilgileri önbellekten alındı")
            return self.hasta_ozellikleri_cache[hasta_id]
        
        try:
            # API'den hasta bilgilerini çek
            logger.info(f"Hasta {hasta_id} demografik bilgileri API'den çekiliyor")
            logger.info(f"{API_BASE_URL}/hastalar/{hasta_id}")
            response = requests.get(f"{API_BASE_URL}/hastalar/{hasta_id}")
            
            if response.status_code != 200:
                logger.error(f"Hasta API hatası: {response.status_code} - {response.text[:100]}...")
                return self._create_default_demografik()
            
            hasta_data = response.json().get('data', {}) if isinstance(response.json(), dict) else response.json()
            
            # Boş yanıt kontrolü
            if not hasta_data:
                logger.warning(f"Hasta {hasta_id} için veri bulunamadı")
                return self._create_default_demografik()
            
            # Gerekli alanları logla
            logger.info(f"Hasta {hasta_id} alanları: {list(hasta_data.keys())}")
            
            # Demografik bilgileri çıkar
            demografik = {
                'yas': hasta_data.get('yas', 0),
                'cinsiyet': hasta_data.get('cinsiyet', 'bilinmiyor'),
                'cinsiyet_encoded': 1 if hasta_data.get('cinsiyet', '').lower() == 'erkek' else 0,
                'boy': hasta_data.get('boy', 0),
                'kilo': hasta_data.get('kilo', 0),
                'vki': hasta_data.get('vki', 0)
            }
            
            logger.info(f"hasta demografik bilgileri :{demografik}")

            # VKI hesapla (eğer mevcut değilse)
            if demografik['vki'] == 0 and demografik['boy'] > 0 and demografik['kilo'] > 0:
                demografik['vki'] = demografik['kilo'] / ((demografik['boy'] / 100) ** 2)
                logger.info(f"Hasta {hasta_id} için VKI hesaplandı: {demografik['vki']}")
            
            # Önbelleğe al
            self.hasta_ozellikleri_cache[hasta_id] = demografik
            
            # Sonuçları logla
            logger.info(f"Hasta {hasta_id} demografik bilgileri alındı: yaş={demografik['yas']}, "
                        f"cinsiyet={demografik['cinsiyet']}, VKI={demografik['vki'] if demografik['vki'] else 0}")
            
            return demografik
                
        except Exception as e:
            logger.error(f"Hasta demografik bilgilerini çekerken hata: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return self._create_default_demografik()
        
    def _create_default_demografik(self):
        """Varsayılan demografik bilgiler oluştur"""
        return {
            'yas': 0, 
            'cinsiyet': 'bilinmiyor',
            'cinsiyet_encoded': 0,
            'boy': 0,
            'kilo': 0,
            'vki': 0
        }

    def save_model(self):
        try:
            logger.info(f"Model kaydediliyor: {self.model_path}")
            model_data = {
                "model": self.model,
                "ilac_lookup": self.ilac_lookup,
                "etken_madde_lookup": self.etken_madde_lookup,
                "model_last_trained": self.model_last_trained,
                "ilac_etki_vektoru": self.ilac_etki_vektoru,
                "model_version": self.model_version,
                "model_metrics": self.model_metrics
            }
            joblib.dump(model_data, self.model_path)
            logger.info(f"Model başarıyla kaydedildi: {self.model_path}")
            return True
        except Exception as e:
            logger.error(f"Model kaydetme hatası: {e}")
            return False

    def load_model(self):
        try:
            logger.info(f"Model yükleniyor: {self.model_path}")
            if not os.path.exists(self.model_path):
                logger.error(f"Model dosyası bulunamadı: {self.model_path}")
                return False
            
            model_data = joblib.load(self.model_path)
            required_keys = ["model", "ilac_lookup", "etken_madde_lookup"]
            missing_keys = [key for key in required_keys if key not in model_data]
            if missing_keys:
                logger.error(f"Model dosyasında eksik anahtarlar: {missing_keys}")
                return False
            
            self.model = model_data["model"]
            self.ilac_lookup = model_data["ilac_lookup"]
            self.etken_madde_lookup = model_data["etken_madde_lookup"]
            self.model_last_trained = model_data.get("model_last_trained")
            self.ilac_etki_vektoru = model_data.get("ilac_etki_vektoru", {})
            self.model_version = model_data.get("model_version", "1.0")
            self.model_metrics = model_data.get("model_metrics", {})
            
            logger.info(f"Model başarıyla yüklendi: {self.model_path} (Versiyon: {self.model_version})")
            return True
        except Exception as e:
            logger.error(f"Model yükleme hatası: {e}")
            return False

    def predict_ilac(self, hasta_id, hastalik_id=None, etken_madde_ids=None, exclude_ilac_ids=None, hasta_demografik=None, hastalik_bilgileri=None, etken_madde_bilgileri=None):
        """
        Belirli bir hasta ve hastalık (veya etken madde) için ilaç önerisi yap
        
        Args:
            hasta_id (int): Hasta ID
            hastalik_id (int, optional): Hastalık ID
            etken_madde_ids (list, optional): Etken madde ID'leri listesi
            exclude_ilac_ids (list, optional): Önerilmeyecek ilaç ID'leri
            hasta_demografik (dict, optional): Laravel'den gelen hasta demografik bilgileri
            hastalik_bilgileri (dict, optional): Laravel'den gelen hastalık bilgileri
            etken_madde_bilgileri (list, optional): Laravel'den gelen etken madde bilgileri
        
        Returns:
            dict: Önerilen ilaçlar ve olasılıkları
        """
        import time
        baslangic_zamani = time.time()
        
        logger.info(f"Tahmin isteği: hasta_id={hasta_id}, hastalik_id={hastalik_id}, etken_madde_ids={etken_madde_ids}, exclude_ilac_ids={exclude_ilac_ids}")
        
        # Model varlığını kontrol et
        if self.model is None:
            logger.warning("Model eğitilmemiş. Otomatik eğitim başlatılıyor...")
            try:
                self.train_model()
                logger.info("Model başarıyla eğitildi")
            except Exception as e:
                logger.error(f"Otomatik model eğitimi başarısız oldu: {str(e)}", exc_info=True)
                return {"error": "Model eğitilemedi"}
                
            if self.model is None:
                logger.error("Eğitim sonrası model hala yok")
                return {"error": "Model eğitilemedi"}
        
        # Parametre kontrolü
        if not hastalik_id and not etken_madde_ids:
            logger.error("Tahmin için gerekli parametreler eksik - hastalık ID veya etken madde ID'leri gerekli")
            return {"error": "Hastalık veya etken madde bilgisi gerekli"}
        
        # Etken madde listesini normalize et
        if etken_madde_ids and not isinstance(etken_madde_ids, list):
            logger.debug(f"Etken madde ID'si listeye dönüştürülüyor: {etken_madde_ids}")
            etken_madde_ids = [etken_madde_ids]
        
        try:
            # Hastanın demografik bilgilerini kullan
            if hasta_demografik:
                logger.info(f"Hasta {hasta_id} demografik bilgileri Laravel'den alındı")
            else:
                # Eğer Laravel'den demografik bilgiler gönderilmemişse önbellek veya API'den al
                logger.info(f"Hasta {hasta_id} için demografik bilgiler alınıyor")
                hasta_demografik = self.get_hasta_demografik_bilgileri(hasta_id)
            
            logger.info(f"Hasta {hasta_id} demografik bilgileri alındı: yaş={hasta_demografik.get('yas')}, cinsiyet={hasta_demografik.get('cinsiyet')}, VKI={hasta_demografik.get('vki')}")
            
            # Hastalık bazlı öneri
            if hastalik_id:
                logger.info(f"Hastalık ID {hastalik_id} için öneri yapılıyor")
                
                # Hastalık bilgilerini kullan
                kategori = "Bilinmiyor"
                hastalik_adi = f"Hastalık {hastalik_id}"
                
                if hastalik_bilgileri:
                    # Laravel'den gelen hastalık bilgilerini kullan
                    kategori = hastalik_bilgileri.get("hastalik_kategorisi", hastalik_bilgileri.get("kategori", "Bilinmiyor"))
                    hastalik_adi = hastalik_bilgileri.get("hastalik_adi", hastalik_bilgileri.get("adi", f"Hastalık {hastalik_id}"))
                    logger.info(f"Hastalık bilgileri Laravel'den alındı - Adı: {hastalik_adi}, Kategori: {kategori}")
                else:
                    # API çağrısı yapmadan varsayılan bilgilerle devam et
                    logger.warning(f"Hastalık ID {hastalik_id} için bilgiler Laravel'den gelmedi ve API çağrısı yapılmayacak")
                
                # Test verisi oluştur - temel özellikler
                test_data = {
                    "hasta_id": [hasta_id],
                    "hastalik_id": [hastalik_id],
                    "hastalik_kategorisi": [kategori]
                }
                
                # Cinsiyet verisini kodla (encode)
                if 'cinsiyet' in hasta_demografik:
                    cinsiyet = hasta_demografik.get('cinsiyet')
                    # Basit bir kodlama örneği (modelinizin bekleyeceği formata uygun olmalı)
                    if cinsiyet == 'Erkek':
                        test_data['cinsiyet_encoded'] = [0]
                    elif cinsiyet == 'Kadın':
                        test_data['cinsiyet_encoded'] = [1]
                    else:
                        test_data['cinsiyet_encoded'] = [2]


                # Demografik özellikleri ekle
                for key, value in hasta_demografik.items():
                    if key != 'cinsiyet':  # Encoded versiyonu kullanılacak
                        test_data[key] = [value] 
                
                logger.debug(f"Oluşturulan test verisi: {test_data}")
                
                # Etken madde bazlı tahmin
                if etken_madde_ids:
                    logger.info(f"Hastalık + {len(etken_madde_ids)} etken madde kombinasyonu ile tahmin yapılıyor")
                    # Birden fazla etken madde varsa, her biri için ayrı tahmin yap
                    all_predictions = []
                    
                    for etken_id in etken_madde_ids:
                        logger.debug(f"Etken madde ID {etken_id} için tahmin yapılıyor")
                        test_data_with_etken = test_data.copy()
                        test_data_with_etken["etken_madde_id"] = [etken_id]
                        test_df = pd.DataFrame(test_data_with_etken)
                        
                        try:
                            # Tahmin
                            probabilities = self.model.predict_proba(test_df)
                            classes = self.model.classes_
                            
                            # Her ilaç için olasılıkları ekle
                            for idx, ilac_id in enumerate(classes):
                                all_predictions.append((ilac_id, probabilities[0][idx]))
                            
                            logger.debug(f"Etken madde {etken_id} için {len(classes)} ilaç tahmini yapıldı")
                        except Exception as e:
                            logger.error(f"Etken madde {etken_id} için tahmin yapılırken hata: {str(e)}", exc_info=True)
                            continue
                    
                    logger.info(f"Toplam {len(all_predictions)} tahmin yapıldı, etken madde uyumuna göre düzenleniyor")
                    
                    # Etken madde uyumuna göre tahminleri ayarla
                    logger.info(f"{len(all_predictions)} tahmin etken madde uyumuna göre ayarlanıyor")
                    all_predictions = self.adjust_predictions_by_active_substances(all_predictions, etken_madde_ids)
                    
                    # Sonuçları formatla
                    result = self.format_prediction_results(all_predictions, exclude_ilac_ids)
                    
                    # Önerileri logla
                    if "recommendations" in result:
                        logger.info(f"{len(result['recommendations'])} ilaç önerisi oluşturuldu")
                    
                    bitis_zamani = time.time()
                    logger.info(f"Tahmin tamamlandı: {len(result.get('recommendations', []))} öneri, {(bitis_zamani - baslangic_zamani):.2f} saniye")
                    return result
                    
                else:
                    # Sadece hastalık bilgisi ile tahmin
                    logger.info("Sadece hastalık bilgisi ile öneri yapılıyor")
                    # En yaygın etken maddeler üzerinden tahmin yap
                    all_etken_madde_ids = list(self.etken_madde_lookup.keys())
                    all_predictions = []
                    
                    # Performans için sınırla
                    sample_size = min(20, len(all_etken_madde_ids))
                    sample_etken_madde_ids = all_etken_madde_ids[:sample_size]
                    
                    logger.info(f"{sample_size} etken madde örneklemi ile hastalık bazlı tahmin yapılıyor")
                    
                    for etken_id in sample_etken_madde_ids:
                        logger.debug(f"Hastalık {hastalik_id} + Etken madde {etken_id} kombinasyonu için tahmin")
                        test_data_with_etken = test_data.copy()
                        test_data_with_etken["etken_madde_id"] = [etken_id]
                        test_df = pd.DataFrame(test_data_with_etken)
                        
                        try:
                            # Tahmin
                            probabilities = self.model.predict_proba(test_df)
                            classes = self.model.classes_
                            
                            # Her ilaç için olasılıkları ekle
                            for idx, ilac_id in enumerate(classes):
                                all_predictions.append((ilac_id, probabilities[0][idx]))
                                
                        except Exception as e:
                            logger.error(f"Etken madde {etken_id} için tahmin hatası: {str(e)}", exc_info=True)
                            continue
                    
                    logger.info(f"Toplam {len(all_predictions)} tahmin yapıldı, sonuçlar formatlanıyor")
                    
                    # Sonuçları formatla
                    result = self.format_prediction_results(all_predictions, exclude_ilac_ids)
                    
                    # Önerileri logla
                    if "recommendations" in result:
                        logger.info(f"{len(result['recommendations'])} ilaç önerisi oluşturuldu")
                    
                    bitis_zamani = time.time()
                    logger.info(f"Tahmin tamamlandı: {len(result.get('recommendations', []))} öneri, {(bitis_zamani - baslangic_zamani):.2f} saniye")
                    return result
            
            # Sadece etken madde bazlı öneri
            elif etken_madde_ids:
                logger.info(f"Sadece {len(etken_madde_ids)} etken madde ile öneri yapılıyor (hastalık bilgisi olmadan)")
                
                # Laravel'den hastalık listesi gelmediyse varsayılan kullan
                hastalik_orneklemi = []
                
                # Varsayılan hastalık listesi oluştur - API çağrısı yapmadan
                if not hastalik_orneklemi:
                    # Performans için sınırlı sayıda örnek hastalık kullan
                    hastalik_orneklemi = [(1, 'Bilinmiyor'), (2, 'Bilinmiyor'), (3, 'Bilinmiyor')]
                    logger.warning("Hastalık listesi Laravel'den gelmedi ve API çağrısı yapılmayacak, varsayılan hastalık ID'leri kullanılacak")
                
                logger.info(f"{len(hastalik_orneklemi)} hastalık ve {len(etken_madde_ids)} etken madde ile tahmin yapılıyor")
                
                all_predictions = []
                prediction_count = 0
                
                # Her hastalık-etken madde kombinasyonu için tahmin yap
                for hastalik_id, kategori in hastalik_orneklemi:
                    # Test verisi oluştur - temel özellikler
                    test_data = {
                        "hasta_id": [hasta_id],
                        "hastalik_id": [hastalik_id],
                        "hastalik_kategorisi": [kategori]
                    }
                    
                    # Demografik özellikleri ekle
                    for key, value in hasta_demografik.items():
                        if key != 'cinsiyet':  # Encoded versiyonu kullanılacak
                            test_data[key] = [value]
                    
                    for etken_id in etken_madde_ids:
                        test_data_with_etken = test_data.copy()
                        test_data_with_etken["etken_madde_id"] = [etken_id]
                        test_df = pd.DataFrame(test_data_with_etken)
                        
                        try:
                            # Tahmin
                            probabilities = self.model.predict_proba(test_df)
                            classes = self.model.classes_
                            
                            # Her ilaç için olasılıkları ekle
                            prediction_count += len(classes)
                            for idx, ilac_id in enumerate(classes):
                                all_predictions.append((ilac_id, probabilities[0][idx]))
                            
                        except Exception as e:
                            # Bazı kombinasyonlar için tahmin yapılamayabilir
                            continue
                
                logger.info(f"Toplam {len(all_predictions)} tahmin yapıldı ({prediction_count} sınıf tahmini)")
                
                # Etken madde uyumuna göre tahminleri ayarla
                logger.info(f"{len(all_predictions)} tahmin etken madde uyumuna göre ayarlanıyor")
                all_predictions = self.adjust_predictions_by_active_substances(all_predictions, etken_madde_ids)

                # Sonuçları formatla
                result = self.format_prediction_results(all_predictions, exclude_ilac_ids)
                
                # Önerileri logla
                if "recommendations" in result:
                    logger.info(f"{len(result['recommendations'])} ilaç önerisi oluşturuldu")
                
                bitis_zamani = time.time()
                logger.info(f"Tahmin tamamlandı: {len(result.get('recommendations', []))} öneri, {(bitis_zamani - baslangic_zamani):.2f} saniye")
                return result
                
        except Exception as e:
            logger.error(f"İlaç tahmini sırasında beklenmeyen hata: {str(e)}", exc_info=True)
            bitis_zamani = time.time()
            logger.info(f"Tahmin başarısız oldu: {(bitis_zamani - baslangic_zamani):.2f} saniye")
            return {"error": str(e)}   

    def adjust_predictions_by_active_substances(self, predictions, target_etken_madde_ids):
        """
        Etken madde uyumuna göre tahminleri düzenle
        
        Args:
            predictions (list): [(ilac_id, olasılık), ...] şeklinde tahmin listesi
            target_etken_madde_ids (list): Hedef etken madde ID'leri
            
        Returns:
            list: Düzenlenmiş tahminler
        """
        
        logger.info(f"{len(predictions)} tahmin etken madde uyumuna göre ayarlanıyor")
        
        if not hasattr(self, 'ilac_etken_lookup'):
            logger.warning("İlaç-etken madde eşleştirmesi (ilac_etken_lookup) bulunamadı")
            return predictions
        
        # Etken madde ID'lerini set'e çevir
        target_etken_set = set(target_etken_madde_ids)
        
        # İlaç-olasılık sözlüğü
        ilac_olasilikar = {}
        
        # İlk geçiş: Her ilaç için en yüksek olasılık
        for ilac_id, prob in predictions:
            # Bu ilaç daha önce işlendi mi?
            if ilac_id in ilac_olasilikar:
                # En yüksek olasılığı tut
                ilac_olasilikar[ilac_id] = max(prob, ilac_olasilikar[ilac_id])
            else:
                ilac_olasilikar[ilac_id] = prob
        
        # İkinci geçiş: Etken madde uyumuna göre puanları ayarla
        adjusted_predictions = []
        
        for ilac_id, prob in ilac_olasilikar.items():
            # İlacın etken maddelerini al
            ilac_etken_ids = self.ilac_etken_lookup.get(ilac_id, [])
            
            if not ilac_etken_ids:
                # Etken madde bilgisi yoksa olasılığı düşür
                adjusted_prob = prob * 0.5
                logger.debug(f"İlaç {ilac_id} için etken madde bilgisi bulunamadı, olasılık 0.5 ile ölçeklendi")
            else:
                # Etken madde ID'lerini set'e çevir
                ilac_etken_set = set(ilac_etken_ids)
                
                # Etken madde eşleşmesi hesapla
                ortak_etken = ilac_etken_set.intersection(target_etken_set)
                
                # Uyum puanı (1.0: tam eşleşme, 0.5: kısmi eşleşme, 0.3: eşleşme yok)
                if len(ortak_etken) == len(target_etken_set) and len(ilac_etken_set) == len(target_etken_set):
                    # Tam eşleşme: Hedeflenen etken maddelerin tamamı ilaçta var ve ilaçta başka etken madde yok
                    uyum_puani = 1.0
                    logger.debug(f"İlaç {ilac_id} için tam etken madde eşleşmesi: {ortak_etken}")
                elif len(ortak_etken) > 0:
                    # Kısmi eşleşme: Hedeflenen etken maddelerden bir kısmı ilaçta var
                    uyum_orani = len(ortak_etken) / len(target_etken_set)
                    uyum_puani = 0.5 + (uyum_orani * 0.5)  # 0.5 - 1.0 arası değer
                    logger.debug(f"İlaç {ilac_id} için kısmi etken madde eşleşmesi: {ortak_etken}, uyum oranı: {uyum_orani:.2f}")
                else:
                    # Eşleşme yok
                    uyum_puani = 0.3
                    logger.debug(f"İlaç {ilac_id} için etken madde eşleşmesi yok")
                
                # Olasılığı uyum puanı ile ayarla
                adjusted_prob = prob * uyum_puani
            
            # Düzeltilmiş olasılıkla ekle
            adjusted_predictions.append((ilac_id, adjusted_prob))
        
        # Olasılık sırasına göre sırala
        adjusted_predictions.sort(key=lambda x: x[1], reverse=True)
        
        logger.info(f"Etken madde uyumuna göre {len(adjusted_predictions)} tahmin ayarlandı")
        return adjusted_predictions

    def format_prediction_results(self, predictions, exclude_ilac_ids=None):
        """ 
        Tahmin sonuçlarını kullanılabilir bir formata dönüştür
        
        Args:
            predictions (list): (ilac_id, olasılık) çiftleri listesi
            exclude_ilac_ids (list, optional): Hariç tutulacak ilaç ID'leri
            
        Returns:
            dict: Formatlı sonuçlar
        """
        if not predictions:
            logger.warning("Format için tahmin sonucu yok")
            return {"recommendations": []}
        
        # Exclude belirtilen ilaçları filtrele
        if exclude_ilac_ids is not None:
            logger.debug(f"{len(exclude_ilac_ids)} ilaç hariç tutuluyor: {exclude_ilac_ids}")
            predictions = [(ilac_id, prob) for ilac_id, prob in predictions if ilac_id not in exclude_ilac_ids]
        
        # İlaç bazında olasılıkları birleştir (ilaç başına en yüksek olasılık)
        ilac_olasilikar = {}
        for ilac_id, prob in predictions:
            ilac_olasilikar[ilac_id] = max(prob, ilac_olasilikar.get(ilac_id, 0))
        
        # İlaç-olasılık çiftlerini oluştur
        ilac_olasilikar_list = [(ilac_id, prob) for ilac_id, prob in ilac_olasilikar.items()]
        
        # Olasılık sırasına göre sırala (azalan)
        ilac_olasilikar_list.sort(key=lambda x: x[1], reverse=True)
        
        # En iyi N tanesini al
        max_recommendations = 5
        top_ilaclar = ilac_olasilikar_list[:max_recommendations]
        
        # Sonuç formatını oluştur
        recommendations = []
        
        # Kullanılacak ilaç id listesi için cache
        processed_ilac_ids = set()
        
        for ilac_id, prob in top_ilaclar:
            # İlaç adını bul
            ilac_adi = self.ilac_lookup.get(ilac_id, f"İlaç_{ilac_id}")
            
            # Etken maddeleri al
            etken_maddeler = []
            
            # İlaç-etken madde eşleştirme verimiz varsa
            if hasattr(self, 'ilac_etken_lookup') and ilac_id in self.ilac_etken_lookup:
                # Bu fonksiyon ilac_etken_lookup'tan etken madde ID'lerini almalı
                etken_ids = self.ilac_etken_lookup.get(ilac_id, [])
                
                # Benzersiz etken madde ID'leri için işlem yap
                unique_etken_ids = set(etken_ids)
                
                for etken_id in unique_etken_ids:
                    etken_adi = self.etken_madde_lookup.get(etken_id, f"Etken madde {etken_id}")
                    etken_maddeler.append({
                        "etken_madde_id": etken_id,
                        "etken_madde_adi": etken_adi
                    })
            else:
                # İlaç-etken madde ilişkilerini prepare_data içinde oluşturmamız gerekiyor
                # Şimdilik boş liste döndür
                logger.warning(f"İlaç {ilac_id} için etken madde bilgisi bulunamadı")
            
            # İlaç önerisini ekle
            recommendations.append({
                "ilac_id": ilac_id,
                "ilac_adi": ilac_adi,
                "olaslik": prob,
                "oneri_puani": round(prob * 100, 2),
                "etken_maddeler": etken_maddeler
            })
            
            # İşlenen ilaç ID'sini işaretleyelim
            processed_ilac_ids.add(ilac_id)
        
        # Sonuçları döndür
        return {
            "recommendations": recommendations
        }

class HybridDrugRecommender:
    """
    Hibrit İlaç Öneri Sistemi
    
    Üç farklı öneri yaklaşımını birleştirir:
    1. Etken madde tabanlı öneri (İçerik tabanlı)
    2. Hastalık-ilaç ilişkisi tabanlı öneri (Bilgi tabanlı)
    3. Hasta-ilaç kullanımları (İşbirlikçi filtreleme)
    """
    
    def __init__(self):
        self.etken_madde_model = None
        self.hastalik_ilac_model = None
        self.hasta_model = None
        self.ilac_lookup = {}
        self.etken_madde_lookup = {}
        self.ilac_etken_vectors = {}
        self.hastalik_ilac_scores = {}
        self.encoder = None
        self.scaler = None
        self.model_version = "2.0"
        self.feature_importances = None
        
    def fit(self, prepared_data):
        """
        Tüm modelleri eğit
        
        Args:
            prepared_data: Hazırlanmış veri yapıları
        """
        # Referanslar ve lookup tablolarını oluştur
        self.ilac_lookup = dict(zip(
            prepared_data['ilaclar']['ilac_id'], 
            prepared_data['ilaclar']['ilac_adi']
        ))
        
        self.etken_madde_lookup = dict(zip(
            prepared_data['etken_maddeler']['etken_madde_id'], 
            prepared_data['etken_maddeler']['etken_madde_adi']
        ))
        
        # 1. Etken Madde Tabanlı Model
        self._train_active_substance_model(prepared_data)
        
        # 2. Hastalık-İlaç İlişki Modeli
        self._train_disease_drug_model(prepared_data)
        
        # 3. Hasta Özellikleri Modeli
        self._train_patient_features_model(prepared_data)
        
        print("Hibrit model eğitimi tamamlandı.")
        return self
    
    def _train_active_substance_model(self, prepared_data):
        """
        Etken madde tabanlı modeli eğit (İçerik tabanlı filtreleme)
        """
        from sklearn.metrics.pairwise import cosine_similarity
        
        # İlaç-etken madde matrisini al
        ilac_etken_df = prepared_data['ilac_etken_matrix']
        
        # Her ilacın etken maddelerini sözlük olarak sakla
        for _, row in ilac_etken_df.iterrows():
            ilac_id = row['ilac_id']
            etken_madde_list = row.get('etken_madde_id', [])
            if etken_madde_list and isinstance(etken_madde_list, list):
                self.ilac_etken_vectors[ilac_id] = etken_madde_list
        
        print(f"Etken madde vektörleri oluşturuldu: {len(self.ilac_etken_vectors)} ilaç")
        
    def _train_disease_drug_model(self, prepared_data):
        """
        Hastalık-ilaç ilişki modelini eğit (Bilgi tabanlı filtreleme)
        """
        # Hastalık-ilaç matrisini al
        hastalik_ilac_df = prepared_data['hastalik_ilac_matrix']
        
        # Hastalık-ilaç skorlarını sözlük olarak sakla
        for _, row in hastalik_ilac_df.iterrows():
            hastalik_id = row['hastalik_id']
            ilac_id = row['ilac_id']
            score = row.get('normalized_count', 0)
            
            if hastalik_id not in self.hastalik_ilac_scores:
                self.hastalik_ilac_scores[hastalik_id] = {}
            
            self.hastalik_ilac_scores[hastalik_id][ilac_id] = score
        
        print(f"Hastalık-ilaç skorları oluşturuldu: {len(self.hastalik_ilac_scores)} hastalık")
        
    def _train_patient_features_model(self, prepared_data):
        """
        Hasta özellikleri tabanlı modeli eğit (Özellik tabanlı)
        """
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.preprocessing import StandardScaler, OneHotEncoder
        from sklearn.compose import ColumnTransformer
        from sklearn.pipeline import Pipeline
        
        # Veri hazırlama
        hastalar_df = prepared_data['hastalar']
        ilac_kullanim_df = pd.DataFrame(prepared_data.get('hasta_ilac_kullanim', []))
        
        # Veri yoksa erken çık
        if hastalar_df.empty or ilac_kullanim_df.empty:
            print("Hasta-ilaç kullanım verisi bulunamadı, hasta özellikleri modeli eğitilemiyor.")
            return
        
        # Hasta-ilaç kullanımlarını birleştir
        hasta_features = pd.merge(
            ilac_kullanim_df,
            hastalar_df,
            on='hasta_id'
        )
        
        # Özellik sütunlarını seç
        categorical_features = ['cinsiyet']
        numerical_features = ['yas', 'vki']
        
        # Eksik özellik sütunlarını kontrol et
        available_cat_features = [f for f in categorical_features if f in hasta_features.columns]
        available_num_features = [f for f in numerical_features if f in hasta_features.columns]
        
        # Veri dönüştürücüleri
        transformers = []
        
        if available_cat_features:
            cat_transformer = OneHotEncoder(handle_unknown='ignore')
            transformers.append(('cat', cat_transformer, available_cat_features))
        
        if available_num_features:
            num_transformer = StandardScaler()
            transformers.append(('num', num_transformer, available_num_features))
        
        # Hiç özellik yoksa erken çık
        if not transformers:
            print("Yeterli hasta özelliği bulunamadı, hasta özellikleri modeli eğitilemiyor.")
            return
        
        # Özellik dönüştürücüsü
        preprocessor = ColumnTransformer(
            transformers=transformers,
            remainder='drop'
        )
        
        # Model pipeline'ı
        model = Pipeline([
            ('preprocessor', preprocessor),
            ('classifier', RandomForestClassifier(
                n_estimators=100,
                max_depth=10,
                min_samples_split=5,
                min_samples_leaf=2,
                random_state=42,
                class_weight='balanced'
            ))
        ])
        
        # Veriyi eğitim için hazırla
        X = hasta_features.drop(['ilac_id'], axis=1)
        y = hasta_features['ilac_id']
        
        # Modeli eğit
        model.fit(X, y)
        
        # Modeli sakla
        self.hasta_model = model
        self.encoder = preprocessor
        
        # Özellik önemlerini sakla (eğer varsa)
        if hasattr(model.named_steps['classifier'], 'feature_importances_'):
            self.feature_importances = model.named_steps['classifier'].feature_importances_
        
        print("Hasta özellikleri modeli eğitildi.")
    
    def predict(self, hasta_id, hastalik_id=None, etken_madde_ids=None, exclude_ilac_ids=None, hasta_demografik=None):
        """
        Hibrit ilaç önerisi yap
        
        Args:
            hasta_id: Hasta ID'si
            hastalik_id: Hastalık ID'si (opsiyonel)
            etken_madde_ids: Etken madde ID'leri (opsiyonel)
            exclude_ilac_ids: Hariç tutulacak ilaçlar (opsiyonel)
            hasta_demografik: Hasta demografik bilgileri (opsiyonel)
            
        Returns:
            recommendations: Önerilen ilaçlar listesi
        """
        # Parametreleri kontrol et
        if not hastalik_id and not etken_madde_ids:
            return {"error": "Hastalık ID veya etken madde ID'leri gerekli"}
        
        # İstek zamanına göre stratejileri değiştir
        # Örneğin, saatin saniyelerine göre ağırlıkları değiştir
        seconds = int(time.time()) % 60
        strategy = seconds % 3  # 0, 1 veya 2
        
        # Ağırlıkları strateji numarasına göre ayarla
        if strategy == 0:
            # Etken madde öncelikli
            etken_madde_weight = 1.2
            hastalik_weight = 0.8
            patient_weight = 0.6
        elif strategy == 1:
            # Hastalık öncelikli
            etken_madde_weight = 0.8
            hastalik_weight = 1.2
            patient_weight = 0.6
        else:
            # Hasta özellikleri öncelikli
            etken_madde_weight = 0.8
            hastalik_weight = 0.6
            patient_weight = 1.2

        # Her modelden önerileri al
        recommendations = {}
        scores = {}
        
        # 1. Etken madde tabanlı öneriler
        if etken_madde_ids:
            etken_madde_recommendations = self._get_active_substance_recommendations(etken_madde_ids)
            for ilac_id, score in etken_madde_recommendations.items():
                if ilac_id not in scores:
                    scores[ilac_id] = []
                scores[ilac_id].append(score * etken_madde_weight)  # Değişken ağırlık
        
        # 2. Hastalık-ilaç ilişkisi tabanlı öneriler
        if hastalik_id:
            hastalik_recommendations = self._get_disease_drug_recommendations(hastalik_id)
            for ilac_id, score in hastalik_recommendations.items():
                if ilac_id not in scores:
                    scores[ilac_id] = []
                scores[ilac_id].append(score * hastalik_weight)  # Hastalık-ilaç ağırlığı 0.8
        
        # 3. Hasta özellikleri tabanlı öneriler
        if hasta_demografik and self.hasta_model:
            patient_recommendations = self._get_patient_features_recommendations(hasta_demografik, hastalik_id)
            for ilac_id, score in patient_recommendations.items():
                if ilac_id not in scores:
                    scores[ilac_id] = []
                scores[ilac_id].append(score * patient_weight)  # Hasta özellikleri ağırlığı 0.6
        
        # Hariç tutulan ilaçları filtrele
        if exclude_ilac_ids:
            for ilac_id in exclude_ilac_ids:
                if ilac_id in scores:
                    del scores[ilac_id]
        
        # Skorları hesapla (ortalama)
        final_scores = {}
        for ilac_id, score_list in scores.items():
            if score_list:
                # Ortalama skorun %10'u kadar rastgele bir değişim ekle
                base_score = sum(score_list) / len(score_list)
                variation = base_score * 0.1  # %10 değişim
                random_factor = random.uniform(-variation, variation)
                final_scores[ilac_id] = base_score + random_factor
        
        # Skorları sırala
        sorted_scores = sorted(final_scores.items(), key=lambda x: x[1], reverse=True)
        
        # En iyi 5 ilaç önerisini hazırla
        recommendations = []
        for ilac_id, score in sorted_scores[:5]:
            ilac_adi = self.ilac_lookup.get(ilac_id, f"İlaç_{ilac_id}")
            
            # Etken maddeleri al
            etken_maddeler = []
            for etken_id in self.ilac_etken_vectors.get(ilac_id, []):
                etken_maddeler.append({
                    "etken_madde_id": etken_id,
                    "etken_madde_adi": self.etken_madde_lookup.get(etken_id, f"Etken madde {etken_id}")
                })
            
            # Öneri ekle
            recommendations.append({
                "ilac_id": ilac_id,
                "ilac_adi": ilac_adi,
                "olaslik": score,
                "oneri_puani": round(score * 100, 2),
                "etken_maddeler": etken_maddeler
            })
        
        return {"recommendations": recommendations}
    
    def _get_active_substance_recommendations(self, etken_madde_ids):
        """
        Etken madde tabanlı öneriler
        
        Args:
            etken_madde_ids: Hedef etken madde ID'leri
            
        Returns:
            recommendations: İlaç ID'leri ve skorları sözlüğü
        """
        # Hedef etken maddeleri set'e çevir
        target_set = set(etken_madde_ids)
        
        # Her ilaç için benzerlik skoru hesapla
        scores = {}
        for ilac_id, etken_madde_list in self.ilac_etken_vectors.items():
            ilac_set = set(etken_madde_list)
            
            # Jaccard benzerliği hesapla
            intersection = len(target_set.intersection(ilac_set))
            union = len(target_set.union(ilac_set))
            
            if union > 0:
                similarity = intersection / union
            else:
                similarity = 0
            
            scores[ilac_id] = similarity
        
        return scores
    
    def _get_disease_drug_recommendations(self, hastalik_id):
        """
        Hastalık-ilaç ilişkisi tabanlı öneriler
        
        Args:
            hastalik_id: Hastalık ID'si
            
        Returns:
            recommendations: İlaç ID'leri ve skorları sözlüğü
        """
        # Hastalık için ilaç skorlarını al
        if hastalik_id in self.hastalik_ilac_scores:
            return self.hastalik_ilac_scores[hastalik_id]
        else:
            return {}  # Bu hastalık için kayıtlı ilişki yok
    
    def _get_patient_features_recommendations(self, hasta_demografik, hastalik_id=None):
        """
        Hasta özellikleri tabanlı öneriler
        
        Args:
            hasta_demografik: Hasta demografik bilgileri
            hastalik_id: Hastalık ID'si (opsiyonel)
            
        Returns:
            recommendations: İlaç ID'leri ve skorları sözlüğü
        """
        # Hasta modelimiz yoksa boş sözlük döndür
        if not self.hasta_model:
            return {}
        
        # Test verisi oluştur
        test_data = {
            'hasta_id': [hasta_demografik.get('hasta_id', 0)],
            'hastalik_id': [hastalik_id] if hastalik_id else [0],
            'yas': [hasta_demografik.get('yas', 0)],
            'cinsiyet': [hasta_demografik.get('cinsiyet', 'bilinmiyor')],
            'vki': [hasta_demografik.get('vki', 0)]
        }
        
        # Test verisi DataFrame'i oluştur
        test_df = pd.DataFrame(test_data)
        
        try:
            # Olasılık tahminlerini al
            proba = self.hasta_model.predict_proba(test_df)
            classes = self.hasta_model.classes_
            
            # İlaç ID'leri ve olasılıkları eşleştir
            recommendations = {}
            for idx, ilac_id in enumerate(classes):
                recommendations[ilac_id] = proba[0][idx]
            
            return recommendations
        except:
            # Tahmin yapılamazsa boş sözlük döndür
            return {}
    
    def save_model(self, path='improved_drug_recommender.joblib'):
        """
        Modeli kaydet
        
        Args:
            path: Kayıt yolu
        """
        import joblib
        
        model_data = {
            'ilac_lookup': self.ilac_lookup,
            'etken_madde_lookup': self.etken_madde_lookup,
            'ilac_etken_vectors': self.ilac_etken_vectors,
            'hastalik_ilac_scores': self.hastalik_ilac_scores,
            'hasta_model': self.hasta_model,
            'encoder': self.encoder,
            'scaler': self.scaler,
            'model_version': self.model_version,
            'feature_importances': self.feature_importances
        }
        
        joblib.dump(model_data, path)
        print(f"Model kaydedildi: {path}")
        
    def load_model(self, path='improved_drug_recommender.joblib'):
        """
        Modeli yükle
        
        Args:
            path: Yükleme yolu
        """
        import joblib
        import os
        
        if not os.path.exists(path):
            print(f"Model dosyası bulunamadı: {path}")
            return False
        
        try:
            model_data = joblib.load(path)
            
            self.ilac_lookup = model_data.get('ilac_lookup', {})
            self.etken_madde_lookup = model_data.get('etken_madde_lookup', {})
            self.ilac_etken_vectors = model_data.get('ilac_etken_vectors', {})
            self.hastalik_ilac_scores = model_data.get('hastalik_ilac_scores', {})
            self.hasta_model = model_data.get('hasta_model')
            self.encoder = model_data.get('encoder')
            self.scaler = model_data.get('scaler')
            self.model_version = model_data.get('model_version', '2.0')
            self.feature_importances = model_data.get('feature_importances')
            
            print(f"Model yüklendi: {path} (Versiyon: {self.model_version})")
            return True
        except Exception as e:
            print(f"Model yükleme hatası: {str(e)}")
            return False





def improved_data_preparation(data):
        """
        İyileştirilmiş veri hazırlama süreci
        
        Args:
            data: API'den çekilen ham veri
            
        Returns:
            prepared_data: Hazırlanmış veri yapıları
        """
        # DataFrame'leri oluştur
        ilaclar_df = pd.DataFrame(data["ilaclar"])
        etken_maddeler_df = pd.DataFrame(data["etken_maddeler"])
        ilac_etken_df = pd.DataFrame(data["ilac_etken_maddeler"])
        hastaliklar_df = pd.DataFrame(data["hastaliklar"])
        hastalar_df = pd.DataFrame(data["hastalar"])
        hasta_hastalik_df = pd.DataFrame(data["hasta_hastaliklar"])
        ilac_kullanim_df = pd.DataFrame(data["hasta_ilac_kullanim"])
        
        # Sütun adlarını standardize et
        column_mappings = {
            'adi': 'ilac_adi',
            'hastalik_adi': 'hastalik_adi',
            'etken_madde_adi': 'etken_madde_adi',
            'kategori': 'hastalik_kategorisi'
        }
        
        for df in [ilaclar_df, etken_maddeler_df, hastaliklar_df]:
            for old_col, new_col in column_mappings.items():
                if old_col in df.columns and new_col not in df.columns:
                    df[new_col] = df[old_col]
        
        # Eksik değerleri akıllıca doldur
        # Sayısal değişkenler için medyan
        for col in ['yas', 'boy', 'kilo', 'vki']:
            if col in hastalar_df.columns:
                hastalar_df[col] = hastalar_df[col].fillna(hastalar_df[col].median())
        
        # Kategorik değişkenler için yaygın kategoriler
        for col in ['cinsiyet', 'hastalik_kategorisi']:
            if col in hastalar_df.columns:
                hastalar_df[col] = hastalar_df[col].fillna(hastalar_df[col].mode()[0])
            elif col in hastaliklar_df.columns:
                hastaliklar_df[col] = hastaliklar_df[col].fillna(hastaliklar_df[col].mode()[0])
        
        # İlaç-etken madde matrisi oluştur (one-hot encoding yerine)
        ilac_etken_matrix = pd.pivot_table(
            ilac_etken_df, 
            values='etken_madde_id', 
            index='ilac_id',
            aggfunc=lambda x: list(x)
        ).reset_index()
        
        # İlaç-hastalık ilişkisi matrisi
        # Önce hasta-hastalık ve hasta-ilaç verilerini birleştir
        hasta_hastalik_ilac = pd.merge(
            hasta_hastalik_df,
            ilac_kullanim_df,
            on='hasta_id'
        )
        
        # Şimdi hastalık-ilaç ilişkisi matrisi oluştur
        hastalik_ilac_matrix = hasta_hastalik_ilac.groupby(['hastalik_id', 'ilac_id']).size().reset_index(name='count')
        hastalik_ilac_normalized = hastalik_ilac_matrix.copy()
        
        # Her hastalık için ilaç kullanım sayılarını normalize et (0-1 arası)
        for hastalik_id in hastalik_ilac_matrix['hastalik_id'].unique():
            mask = hastalik_ilac_matrix['hastalik_id'] == hastalik_id
            max_count = hastalik_ilac_matrix.loc[mask, 'count'].max()
            if max_count > 0:  # Sıfıra bölme hatasını önle
                hastalik_ilac_normalized.loc[mask, 'normalized_count'] = hastalik_ilac_matrix.loc[mask, 'count'] / max_count
            else:
                hastalik_ilac_normalized.loc[mask, 'normalized_count'] = 0
        
        # Hazırlanmış verileri döndür
        prepared_data = {
            'ilaclar': ilaclar_df,
            'etken_maddeler': etken_maddeler_df,
            'ilac_etken_matrix': ilac_etken_matrix,
            'hastaliklar': hastaliklar_df,
            'hastalar': hastalar_df,
            'hastalik_ilac_matrix': hastalik_ilac_normalized
        }
        
        return prepared_data


# Global model instance
ilac_oneri_model = IlacOneriModel()

drug_recommender = HybridDrugRecommender()

@app.route("/")
def index():
    """API ana sayfası"""
    model_status = "trained" if ilac_oneri_model.model is not None else "not_trained"
    
    return jsonify({
        "status": "running",
        "model_status": model_status,
        "description": "İlaç Öneri Sistemi API",
        "version": ilac_oneri_model.model_version,
        "endpoints": [
            {"path": "/train", "method": "POST", "description": "Modeli eğit (force_retrain parametresi opsiyonel)"},
            {"path": "/predict", "method": "POST", "description": "İlaç tahmini yap (hasta_id, hastalik_id veya etken_madde_ids gerekli)"},
            {"path": "/model-info", "method": "GET", "description": "Model bilgilerini göster"},
            {"path": "/ilac-info/{ilac_id}", "method": "GET", "description": "İlaç bilgilerini göster"},
            {"path": "/etken-maddeler", "method": "GET", "description": "Tüm etken maddeleri listele"}
        ]
    })

@app.route("/train", methods=["POST"])
def train_model():
    """Model eğitimi endpoint'i"""
    try:
        force_retrain = request.json.get("force_retrain", False) if request.is_json else False
        logger.info(f"Model eğitimi isteği alındı. force_retrain={force_retrain}")
        
        # Eğitim öncesi durum kontrolü
        model_existed = hasattr(drug_recommender, 'ilac_lookup') and bool(drug_recommender.ilac_lookup)
        
        # Verileri çek
        data = ilac_oneri_model.fetch_data()
        
        # Verileri hazırla
        prepared_data = improved_data_preparation(data)
        
        # Modeli eğit
        drug_recommender.fit(prepared_data)
        
        # Modeli kaydet
        drug_recommender.save_model()
        
        # Eğitim sonucunu hazırla
        return jsonify({
            "status": "success",
            "message": "Model başarıyla eğitildi" if not model_existed else "Model başarıyla güncellendi",
            "model_info": {
                "version": drug_recommender.model_version,
                "ilac_count": len(drug_recommender.ilac_lookup),
                "etken_madde_count": len(drug_recommender.etken_madde_lookup),
                "hastalik_count": len(drug_recommender.hastalik_ilac_scores)
            }
        })
    except Exception as e:
        logger.error(f"Model eğitimi sırasında hata: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route("/predict", methods=["POST"])
def predict():
    """İlaç tahmin endpoint'i"""
    start_time = datetime.datetime.now()
    
    if not request.is_json:
        return jsonify({"error": "JSON verisi gerekli"}), 400
    
    data = request.json
    hasta_id = data.get("hasta_id")
    hastalik_id = data.get("hastalik_id")
    etken_madde_ids = data.get("etken_madde_ids")
    exclude_ilac_ids = data.get("exclude_ilac_ids")
    hasta_demografik = data.get('hasta_demografik', {})
    
    # Log isteği
    logger.info(f"Tahmin isteği: hasta_id={hasta_id}, hastalik_id={hastalik_id}, "
                f"etken_madde_ids={etken_madde_ids}, exclude_ilac_ids={exclude_ilac_ids}")
    
    # Parametre doğrulama
    if not hasta_id:
        return jsonify({"error": "Hasta ID gerekli"}), 400
    
    if not hastalik_id and not etken_madde_ids:
        return jsonify({"error": "Hastalık ID veya Etken Madde ID'leri gerekli"}), 400
    
    # Model varlığını kontrol et
    if not hasattr(drug_recommender, 'ilac_lookup') or not drug_recommender.ilac_lookup:
        # Modeli yüklemeyi dene
        if os.path.exists('improved_drug_recommender.joblib'):
            logger.info("Model yükleniyor...")
            drug_recommender.load_model()
        else:
            logger.warning("Tahmin isteği geldi ama model eğitilmemiş")
            return jsonify({"error": "Model henüz eğitilmemiş. Lütfen önce /train endpoint'ini kullanın."}), 400
    
    # Tahmin yap
    result = drug_recommender.predict(
        hasta_id=hasta_id, 
        hastalik_id=hastalik_id, 
        etken_madde_ids=etken_madde_ids,
        exclude_ilac_ids=exclude_ilac_ids,
        hasta_demografik=hasta_demografik
    )
    
    # Hata kontrolü
    if "error" in result:
        return jsonify(result), 400
    
    # İşlem süresini hesapla
    end_time = datetime.datetime.now()
    duration = (end_time - start_time).total_seconds()
    logger.info(f"Tahmin tamamlandı: {len(result.get('recommendations', []))} öneri, {duration:.2f} saniye")
    
    return jsonify(result)

@app.route("/model-info", methods=["GET"])
def model_info():
    """Model bilgilerini gösteren endpoint"""
    if not hasattr(drug_recommender, 'ilac_lookup') or not drug_recommender.ilac_lookup:
        return jsonify({
            "status": "not_trained",
            "message": "Model henüz eğitilmemiş"
        })
    
    # İstatistikleri hazırla
    model_stats = {
        "status": "trained",
        "version": drug_recommender.model_version,
        "total_ilaclar": len(drug_recommender.ilac_lookup),
        "total_etken_maddeler": len(drug_recommender.etken_madde_lookup),
        "total_hastaliklar": len(drug_recommender.hastalik_ilac_scores)
    }
    
    return jsonify(model_stats)


@app.route("/ilac-info/<int:ilac_id>", methods=["GET"])
def ilac_info(ilac_id):
    """Belirli bir ilacın bilgilerini gösteren endpoint"""
    # İlaç adını lookup tablosundan al
    ilac_adi = ilac_oneri_model.ilac_lookup.get(ilac_id)
    
    # İlacın etken maddelerini al
    etken_maddeler = []
    if ilac_id in ilac_oneri_model.ilac_etki_vektoru:
        for etken_id in ilac_oneri_model.ilac_etki_vektoru[ilac_id]:
            etken_adi = ilac_oneri_model.etken_madde_lookup.get(etken_id, f"Etken Madde {etken_id}")
            etken_maddeler.append({
                "etken_madde_id": etken_id,
                "etken_madde_adi": etken_adi
            })
    
    # İlaç bilgilerini hazırla
    ilac_info = {
        "ilac_id": ilac_id,
        "ilac_adi": ilac_adi or f"İlaç {ilac_id}",
        "etken_maddeler": etken_maddeler
    }
    
    # İlaç API'den bilgi çek (opsiyonel)
    try:
        response = requests.get(f"{API_BASE_URL}/ilaclar/{ilac_id}")
        if response.status_code == 200:
            api_data = response.json().get('data', {}) if isinstance(response.json(), dict) else response.json()
            
            # API'den gelen ilac bilgilerini ekle
            if isinstance(api_data, dict):
                for key, value in api_data.items():
                    if key not in ilac_info and key != "etken_maddeler":
                        ilac_info[key] = value
    except:
        pass
    
    return jsonify(ilac_info)

@app.route("/etken-maddeler", methods=["GET"])
def list_etken_maddeler():
    """Tüm etken maddeleri listeleyen endpoint"""
    etken_maddeler = []
    
    for etken_id, etken_adi in ilac_oneri_model.etken_madde_lookup.items():
        etken_maddeler.append({
            "etken_madde_id": etken_id,
            "etken_madde_adi": etken_adi
        })
    
    return jsonify({
        "count": len(etken_maddeler),
        "etken_maddeler": etken_maddeler
    })

@app.errorhandler(404)
def not_found(e):
    """404 hatası için özel yanıt"""
    return jsonify({
        "status": "error",
        "message": "İstenen endpoint bulunamadı",
        "available_endpoints": ["/", "/train", "/predict", "/model-info", "/ilac-info/{ilac_id}", "/etken-maddeler"]
    }), 404

@app.errorhandler(500)
def server_error(e):
    """500 hatası için özel yanıt"""
    logger.error(f"Sunucu hatası: {str(e)}")
    return jsonify({
        "status": "error",
        "message": "Sunucu hatası, lütfen log dosyalarını kontrol edin"
    }), 500

# Uygulama başlangıç kodları
if __name__ == "__main__":
    # Uygulama başlangıç bilgisi
    logger.info("Geliştirilmiş İlaç Öneri Sistemi başlatılıyor...")
    logger.info(f"API URL: {API_BASE_URL}")
    
    # Uygulama başlatıldığında modeli yükle
    if os.path.exists('improved_drug_recommender.joblib'):
        logger.info("Mevcut model dosyası bulundu, yükleniyor...")
        if drug_recommender.load_model():
            logger.info("Model başarıyla yüklendi")
        else:
            logger.error("Model yüklenemedi")
    else:
        logger.info("Model dosyası bulunamadı, eğitim gerekli")
    
    # Uygulama bilgilerini logla
    logger.info(f"Model durumu: {'Eğitilmiş' if hasattr(drug_recommender, 'ilac_lookup') and drug_recommender.ilac_lookup else 'Eğitilmemiş'}")
    if hasattr(drug_recommender, 'ilac_lookup'):
        logger.info(f"İlaç sayısı: {len(drug_recommender.ilac_lookup)}")
    if hasattr(drug_recommender, 'etken_madde_lookup'):
        logger.info(f"Etken madde sayısı: {len(drug_recommender.etken_madde_lookup)}")
    
    # Uygulamayı başlat
    app.run(host="0.0.0.0", port=5000, debug=True)