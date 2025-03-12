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
            target = pd.Series()
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
                left_on="hasta_id",
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
                
                # Miktar yoksa ekle
                if 'miktar' not in ilac_etken_merged.columns:
                    ilac_etken_merged['miktar'] = 1.0
                    
                # İlaç kullanımları ve etken maddeleri birleştir
                kullanim_etken = pd.merge(
                    ilac_kullanim_merged,
                    ilaclar_df,
                    left_on="ilac_id",
                    right_on="ilac_id",
                    how="left"
                )
                
                # Etken madde ID eksikse NaN'lerden temizle
                if 'ilac_id' in kullanim_etken.columns:
                    kullanim_etken = kullanim_etken.dropna(subset=['ilac_id'])
            else:
                # Veri yoksa, ilac_kullanim_merged'i kullan ve ilac_id ekle
                kullanim_etken = ilac_kullanim_merged.copy()
                kullanim_etken['ilac_id'] = np.nan
            
            # 5. Hasta, hastalık ve kullanılan ilaçlar/etken maddeler
            # Verilerde sorun varsa kontrol et
            if len(hasta_hastalik_merged) == 0 or len(kullanim_etken) == 0:
                logger.warning("Birleştirme sonrası veri kalmadı")
                features = pd.DataFrame()
                target = pd.Series()
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
                target = pd.Series()
                return features, target
            
            # 6. Hasta demografik bilgileri de ekle (varsa)
            if len(hastalar_demo) > 0:
                training_data = pd.merge(
                    training_data,
                    hastalar_demo,
                    left_on="hasta_id",
                    right_on="hasta_id",
                    how="left",
                    suffixes=("", "_hasta")
                )
             
            # Veri var mı kontrol et
            if len(training_data) == 0:
                logger.warning("Eğitim için veri yok")
                features = pd.DataFrame()
                target = pd.Series()
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
                target = pd.Series()
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
            target = pd.Series()
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
        
        logger.info(f"Mevcut metrikler - Accuracy: {accuracy:.4f if accuracy else 'None'}, "
                    f"Precision: {precision:.4f if precision else 'None'}, "
                    f"Recall: {recall:.4f if recall else 'None'}, "
                    f"F1: {f1:.4f if f1 else 'None'}")
        
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

    def predict_ilac(self, hasta_id, hastalik_id=None, etken_madde_ids=None, exclude_ilac_ids=None):
        """
        Belirli bir hasta ve hastalık (veya etken madde) için ilaç önerisi yap
        
        Args:
            hasta_id (int): Hasta ID
            hastalik_id (int, optional): Hastalık ID
            etken_madde_ids (list, optional): Etken madde ID'leri listesi
            exclude_ilac_ids (list, optional): Önerilmeyecek ilaç ID'leri
        
        Returns:
            dict: Önerilen ilaçlar ve olasılıkları
        """
        # Model varlığını kontrol et
        if self.model is None:
            logger.error("Model eğitilmemiş. Önce model eğitilmeli.")
            try:
                logger.info("Model otomatik olarak eğitilmeye çalışılıyor...")
                self.train_model()
            except Exception as e:
                logger.error(f"Otomatik model eğitimi başarısız: {e}")
                return {"error": "Model eğitilemedi"}
                
            if self.model is None:
                return {"error": "Model eğitilemedi"}
        
        # Parametre kontrolü
        if not hastalik_id and not etken_madde_ids:
            logger.error("Hastalık veya etken madde bilgisi eksik")
            return {"error": "Hastalık veya etken madde bilgisi gerekli"}
        
        # Etken madde listesini normalize et
        if etken_madde_ids and not isinstance(etken_madde_ids, list):
            etken_madde_ids = [etken_madde_ids]
        
        try:
            # Hastanın demografik bilgilerini çek
            logger.info(f"Hasta {hasta_id} için ilaç tahmini başlatılıyor")
            hasta_demografik = self.get_hasta_demografik_bilgileri(hasta_id)
            
            # Hastalık bazlı öneri
            if hastalik_id:
                logger.info(f"Hastalık {hastalik_id} için öneri yapılıyor")
                logger.info(f"{API_BASE_URL}/hastaliklar/{hastalik_id}")
                # Hastalık bilgilerini çek
                try:
                    response = requests.get(f"{API_BASE_URL}/hastaliklar/{hastalik_id}")
                    if response.status_code != 200:
                        logger.error(f"Hastalık bilgisi çekilemedi: {response.status_code}")
                        return {"error": f"Hastalık bilgisi çekilemedi (HTTP {response.status_code})"}
                        
                    hastalik_data = response.json().get('data', {}) if isinstance(response.json(), dict) else response.json()
                    
                    # Hastalık kategorisini belirle
                    if isinstance(hastalik_data, dict):
                        kategori = hastalik_data.get("hastalik_kategorisi", hastalik_data.get("hastalik_kategorisi", "Bilinmiyor"))
                        hastalik_adi = hastalik_data.get("hastalik_adi", hastalik_data.get("hastalik_adi", f"Hastalık {hastalik_id}"))
                        logger.info(f"Hastalık adı: {hastalik_adi}, Kategori: {kategori}")
                    else:
                        logger.error(f"Hastalık verisi yanlış formatta: {type(hastalik_data)}")
                        kategori = "Bilinmiyor"
                except Exception as e:
                    logger.error(f"Hastalık bilgisi çekerken hata: {e}")
                    kategori = "Bilinmiyor"
                
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
                
                # Etken madde bazlı tahmin
                if etken_madde_ids:
                    logger.info(f"Hastalık + {len(etken_madde_ids)} etken madde ile öneri yapılıyor")
                    # Birden fazla etken madde varsa, her biri için ayrı tahmin yap
                    all_predictions = []
                    for etken_id in etken_madde_ids:
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
                            logger.error(f"Etken madde {etken_id} için tahmin hatası: {e}")
                            continue
                    
                    # Etken madde uyumuna göre tahminleri ayarla
                    all_predictions = self.adjust_predictions_by_active_substances(all_predictions, etken_madde_ids)
                    
                    # Sonuçları formatla
                    return self.format_prediction_results(all_predictions, exclude_ilac_ids)
                    
                else:
                    # Sadece hastalık bilgisi ile tahmin
                    logger.info("Sadece hastalık bilgisi ile öneri yapılıyor")
                    # En yaygın etken maddeler üzerinden tahmin yap
                    all_etken_madde_ids = list(self.etken_madde_lookup.keys())
                    all_predictions = []
                    
                    # Performans için sınırla
                    sample_size = min(20, len(all_etken_madde_ids))
                    sample_etken_madde_ids = all_etken_madde_ids[:sample_size]
                    
                    logger.info(f"{sample_size} etken madde üzerinden hastalık tahmini yapılıyor")
                    
                    for etken_id in sample_etken_madde_ids:
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
                            logger.error(f"Etken madde {etken_id} için tahmin hatası: {e}")
                            continue
                    
                    # Sonuçları formatla
                    return self.format_prediction_results(all_predictions, exclude_ilac_ids)
            
            # Sadece etken madde bazlı öneri
            elif etken_madde_ids:
                logger.info(f"Sadece {len(etken_madde_ids)} etken madde ile öneri yapılıyor")
                # Tüm hastalıklar için tahmin yap ve ortalama al
                try:
                    response = requests.get(f"{API_BASE_URL}/hastaliklar")
                    tum_hastaliklar = response.json().get('data', []) if isinstance(response.json(), dict) else response.json()
                    
                    # Hastalıkların ID ve kategori bilgilerini çıkar
                    hastalik_bilgileri = []
                    
                    # Hastalıkları kontrol et
                    if isinstance(tum_hastaliklar, list) and len(tum_hastaliklar) > 0:
                        for hastalik in tum_hastaliklar:
                            if isinstance(hastalik, dict):
                                hastalik_id = hastalik.get('id', hastalik.get('hastalik_id'))
                                kategori = hastalik.get('kategori', hastalik.get('hastalik_kategorisi', 'Bilinmiyor'))
                                if hastalik_id:
                                    hastalik_bilgileri.append((hastalik_id, kategori))
                    
                    # Performans için sınırla
                    if len(hastalik_bilgileri) > 10:
                        import random
                        hastalik_ornekleri = random.sample(hastalik_bilgileri, 10)
                    else:
                        hastalik_ornekleri = hastalik_bilgileri
                        
                except Exception as e:
                    logger.error(f"Hastalık listesi alınırken hata: {e}")
                    # Varsayılan liste oluştur
                    hastalik_ornekleri = [(1, 'Bilinmiyor')]
                
                logger.info(f"{len(hastalik_ornekleri)} hastalık ve {len(etken_madde_ids)} etken madde ile tahmin yapılıyor")
                
                all_predictions = []
                
                # Her hastalık-etken madde kombinasyonu için tahmin yap
                for hastalik_id, kategori in hastalik_ornekleri:
                    # Test verisi oluştur - temel özellikler
                    test_data = {
                        "hasta_id": [hasta_id],
                        "hastalik_id": [hastalik_id],
                        "kategori": [kategori]
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
                            for idx, ilac_id in enumerate(classes):
                                all_predictions.append((ilac_id, probabilities[0][idx]))
                        except Exception as e:
                            # Bazı kombinasyonlar için tahmin yapılamayabilir
                            continue
                
                # Etken madde uyumuna göre tahminleri ayarla
                all_predictions = self.adjust_predictions_by_active_substances(all_predictions, etken_madde_ids)
                
                # Sonuçları formatla
                return self.format_prediction_results(all_predictions, exclude_ilac_ids)
                
        except Exception as e:
            logger.error(f"Tahmin sırasında hata: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return {"error": str(e)}

    def adjust_predictions_by_active_substances(self, predictions, etken_madde_ids):
        """
        Etken madde uyumuna göre tahminleri ayarla
        
        Args:
            predictions (list): (ilac_id, olasılık) çiftleri listesi
            etken_madde_ids (list): İstenen etken madde ID'leri
            
        Returns:
            list: Ayarlanmış tahmin listesi
        """
        if not etken_madde_ids or not self.ilac_etki_vektoru:
            return predictions
        
        logger.info(f"{len(predictions)} tahmin etken madde uyumuna göre ayarlanıyor")
        
        adjusted_predictions = []
        
        for ilac_id, prob in predictions:
            # İlacın içerdiği etken maddeler
            ilac_etken_maddeler = self.ilac_etki_vektoru.get(ilac_id, [])
            
            # Etken madde örtüşme oranı
            matching = len(set(ilac_etken_maddeler).intersection(set(etken_madde_ids)))
            total = len(etken_madde_ids)
            
            # Uyum faktörü (0.0 - 1.0)
            match_factor = matching / total if total > 0 else 0
            
            # Olasılığı uyum faktörüne göre ayarla (maksimum %50 artış)
            adjusted_prob = prob * (1.0 + 0.5 * match_factor)
            
            adjusted_predictions.append((ilac_id, adjusted_prob))
        
        return adjusted_predictions

    def format_prediction_results(self, all_predictions, exclude_ilac_ids=None):
        """
        Tahmin sonuçlarını formatla ve istenmeyen ilaçları filtrele
        
        Args:
            all_predictions (list): (ilac_id, olasılık) çiftleri listesi
            exclude_ilac_ids (list): Filtrelenecek ilaç ID'leri
            
        Returns:
            dict: Formatlanmış öneri sonuçları
        """
        # Her ilaç için ortalama olasılık hesapla
        ilac_probabilities = defaultdict(list)
        for ilac_id, prob in all_predictions:
            ilac_probabilities[ilac_id].append(prob)
        
        avg_probabilities = [(ilac_id, sum(probs)/len(probs)) for ilac_id, probs in ilac_probabilities.items() if len(probs) > 0]
        sorted_predictions = sorted(avg_probabilities, key=lambda x: x[1], reverse=True)
        
        # İstenmeyen ilaçları filtrele
        if exclude_ilac_ids:
            sorted_predictions = [p for p in sorted_predictions if p[0] not in exclude_ilac_ids]
        
        # Sonuçları formatla
        top_n = 5  # En yüksek olasılıklı 5 ilaç
        results = []
        
        for ilac_id, probability in sorted_predictions[:top_n]:
            # İlaç adını al
            ilac_adi = self.ilac_lookup.get(ilac_id)
            if ilac_adi is None:
                # API'den ilaç bilgisini çek
                try:
                    response = requests.get(f"{API_BASE_URL}/ilaclar/{ilac_id}")
                    ilac_data = response.json().get('data', {}) if isinstance(response.json(), dict) else response.json()
                    ilac_adi = ilac_data.get('ilac_adi', ilac_data.get('ad', f"İlaç {ilac_id}"))
                    # Lookup tablosuna ekle
                    self.ilac_lookup[ilac_id] = ilac_adi
                except:
                    ilac_adi = f"İlaç {ilac_id}"
            
            # Etken maddeleri al (varsa)
            etken_maddeler = []
            if ilac_id in self.ilac_etki_vektoru:
                etken_ids = self.ilac_etki_vektoru[ilac_id]
                for etken_id in etken_ids:
                    etken_adi = self.etken_madde_lookup.get(etken_id, f"Etken Madde {etken_id}")
                    etken_maddeler.append({"etken_madde_id": etken_id, "etken_madde_adi": etken_adi})
            
            results.append({
                "ilac_id": int(ilac_id),
                "ilac_adi": ilac_adi,
                "olaslik": float(probability),
                "oneri_puani": min(100, round(float(probability) * 100, 2)),
                "etken_maddeler": etken_maddeler
            })
        
        logger.info(f"{len(results)} ilaç önerisi oluşturuldu")
        
        return {
            "oneriler": results,
            "oneri_zamani": datetime.datetime.now().isoformat()
        }

# Global model instance
ilac_oneri_model = IlacOneriModel()

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
        
        # Eğitim başlamadan önce mevcut model durumunu kontrol et
        model_existed = ilac_oneri_model.model is not None
        
        # Modeli eğit
        accuracy, precision, recall, f1 = ilac_oneri_model.train_model(force_retrain=force_retrain)
        
        # Eğitim sonucunu hazırla
        if accuracy is None:
            return jsonify({
                "status": "error",
                "message": "Model eğitimi başarısız oldu"
            }), 500
        
        return jsonify({
            "status": "success",
            "message": "Model başarıyla eğitildi" if not model_existed else "Model başarıyla güncellendi",
            "metrics": {
                "accuracy": float(accuracy) if accuracy is not None else None,
                "precision": float(precision) if precision is not None else None,
                "recall": float(recall) if recall is not None else None,
                "f1": float(f1) if f1 is not None else None
            },
            "model_info": {
                "version": ilac_oneri_model.model_version,
                "trained_at": ilac_oneri_model.model_last_trained.isoformat() if ilac_oneri_model.model_last_trained else None,
                "ilac_count": len(ilac_oneri_model.ilac_lookup),
                "etken_madde_count": len(ilac_oneri_model.etken_madde_lookup)
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
    
    # Log isteği
    logger.info(f"Tahmin isteği: hasta_id={hasta_id}, hastalik_id={hastalik_id}, "
                f"etken_madde_ids={etken_madde_ids}, exclude_ilac_ids={exclude_ilac_ids}")
    
    # Parametre doğrulama
    if not hasta_id:
        return jsonify({"error": "Hasta ID gerekli"}), 400
    
    if not hastalik_id and not etken_madde_ids:
        return jsonify({"error": "Hastalık ID veya Etken Madde ID'leri gerekli"}), 400
    
    # Model varlığını kontrol et
    if ilac_oneri_model.model is None:
        logger.warning("Tahmin isteği geldi ama model eğitilmemiş")
        return jsonify({"error": "Model henüz eğitilmemiş. Lütfen önce /train endpoint'ini kullanın."}), 400
    
    # Tahmin yap
    result = ilac_oneri_model.predict_ilac(
        hasta_id=hasta_id,
        hastalik_id=hastalik_id,
        etken_madde_ids=etken_madde_ids,
        exclude_ilac_ids=exclude_ilac_ids
    )
    
    # Hata kontrolü
    if "error" in result:
        return jsonify(result), 400
    
    # Yanıt hazırlanıyor
    end_time = datetime.datetime.now()
    processing_time = (end_time - start_time).total_seconds()
    
    # Yanıta ek bilgiler ekle
    result["processing_time_seconds"] = processing_time
    result["timestamp"] = end_time.isoformat()
    
    logger.info(f"Tahmin tamamlandı: {len(result.get('oneriler', []))} öneri, {processing_time:.2f} saniye")
    
    return jsonify(result)

@app.route("/model-info", methods=["GET"])
def model_info():
    """Model bilgilerini gösteren endpoint"""
    if ilac_oneri_model.model is None:
        return jsonify({
            "status": "not_trained",
            "message": "Model henüz eğitilmemiş"
        })
    
    # Model metriklerini al
    metrics = ilac_oneri_model.model_metrics or {}
    
    # İstatistikleri hazırla
    model_stats = {
        "status": "trained",
        "version": ilac_oneri_model.model_version,
        "last_trained": ilac_oneri_model.model_last_trained.isoformat() if ilac_oneri_model.model_last_trained else None,
        "total_ilaclar": len(ilac_oneri_model.ilac_lookup),
        "total_etken_maddeler": len(ilac_oneri_model.etken_madde_lookup),
        "metrics": {
            "accuracy": metrics.get('accuracy'),
            "precision": metrics.get('precision'),
            "recall": metrics.get('recall'),
            "f1": metrics.get('f1'),
            "samples_count": metrics.get('samples_count')
        }
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

if __name__ == "__main__":
    # Uygulama başlangıç bilgisi
    logger.info("İlaç Öneri Sistemi başlatılıyor...")
    logger.info(f"API URL: {API_BASE_URL}")
    logger.info(f"Model dosya yolu: {ilac_oneri_model.model_path}")
    
    # Uygulama başlatıldığında modeli yükle veya eğit
    if os.path.exists(ilac_oneri_model.model_path):
        logger.info("Mevcut model dosyası bulundu, yükleniyor...")
        if ilac_oneri_model.load_model():
            logger.info("Model başarıyla yüklendi")
        else:
            logger.error("Model yüklenemedi")
    else:
        logger.info("Model dosyası bulunamadı, eğitim gerekli")
        try:
            logger.info("Otomatik model eğitimi başlatılıyor...")
            ilac_oneri_model.train_model()
            logger.info("Model eğitimi tamamlandı")
        except Exception as e:
            logger.error(f"Başlangıç model eğitimi sırasında hata: {e}")
            import traceback
            logger.error(traceback.format_exc())
    
    # Uygulama bilgilerini logla
    logger.info(f"Model durumu: {'Eğitilmiş' if ilac_oneri_model.model is not None else 'Eğitilmemiş'}")
    logger.info(f"İlaç sayısı: {len(ilac_oneri_model.ilac_lookup)}")
    logger.info(f"Etken madde sayısı: {len(ilac_oneri_model.etken_madde_lookup)}")
    logger.info("Flask uygulaması başlatılıyor...")
    
    # Uygulamayı başlat
    app.run(host="0.0.0.0", port=5000, debug=True)