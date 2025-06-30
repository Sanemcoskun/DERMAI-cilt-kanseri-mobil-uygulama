# DermAI - Cilt Lezyonu Sınıflandırma Sistemi

Bu proje, Flutter mobil uygulaması ve FastAPI backend kullanarak cilt lezyonu sınıflandırma işlemi yapan bir sistemdir. HAM10000 veri seti üzerinde eğitilmiş MobileNet V2 modeli kullanılarak 7 farklı cilt lezyonu türünü sınıflandırır.

## 🎯 Özellikler

- **Flutter Mobil Uygulama**: Kullanıcı dostu arayüz ile resim çekme/seçme
- **FastAPI Backend**: Yüksek performanslı API servisi
- **PyTorch Model**: MobileNet V2 mimarisi ile eğitilmiş model
- **7 Sınıf Tanıma**: Farklı cilt lezyonu türlerini sınıflandırma
- **Risk Değerlendirmesi**: Otomatik risk seviyesi belirleme
- **Medikal Öneriler**: Sınıflandırma sonucuna göre öneriler

## 🏥 Desteklenen Cilt Lezyonu Sınıfları

| Kısaltma | Tam Adı | Türkçe Açıklama |
|----------|---------|-----------------|
| `akiec` | Actinic Keratoses | Güneş Lekesi |
| `bcc` | Basal Cell Carcinoma | Bazal Hücreli Karsinom |
| `bkl` | Benign Keratosis | İyi Huylu Keratoz |
| `df` | Dermatofibroma | Dermatofibrom |
| `mel` | Melanoma | Melanom |
| `nv` | Melanocytic Nevus | Melanositik Nevüs |
| `vasc` | Vascular Lesion | Vasküler Lezyon |

## 🏗️ Sistem Mimarisi

```
┌─────────────────┐    HTTP/Multipart    ┌──────────────────┐
│                 │    POST /predict     │                  │
│  Flutter App    │────────────────────▶ │  FastAPI Backend │
│                 │                      │                  │
│ • Image Picker  │                      │ • Model Loading  │
│ • UI Components │                      │ • Image Process  │
│ • Result Display│◄────────────────────│ • PyTorch Model  │
└─────────────────┘     JSON Response    └──────────────────┘
```

## 🚀 Kurulum

### Backend Kurulumu

1. **Python Ortamı Hazırlayın:**
```bash
cd fastapi_backend
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac
```

2. **Gerekli Paketleri Yükleyin:**
```bash
pip install -r requirements.txt
```

3. **Model Dosyasını Yerleştirin:**
- `mobilenet_skin_96.pt` dosyasını backend dizinine koyun

4. **Sunucuyu Başlatın:**
```bash
python main.py
```

### Flutter Uygulaması Kurulumu

1. **Bağımlılıkları Yükleyin:**
```bash
cd dermai_app
flutter pub get
```

2. **Servisi Güncelleyin:**
- `lib/services/skin_analysis_service.dart` dosyasında IP adresini kontrol edin

3. **Uygulamayı Çalıştırın:**
```bash
flutter run
```

## 📱 Flutter Implementasyonu

### Gerekli Paketler (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.4  # Kamera ve galeri erişimi
  http: ^1.1.0          # HTTP istekleri
  provider: ^6.0.5      # State management
```

### Ana Servis (SkinAnalysisService)
```dart
class SkinAnalysisService {
  static const String baseUrl = '...';
  
  Future<Map<String, dynamic>> analyzeImage(File imageFile, String region) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
    
    // Resim dosyasını ekle
    var multipartFile = await http.MultipartFile.fromPath(
      'file', imageFile.path, filename: 'skin_image.jpg'
    );
    request.files.add(multipartFile);
    request.fields['region'] = region;
    
    // İsteği gönder ve yanıtı işle
    var response = await http.Response.fromStream(await request.send());
    return json.decode(response.body);
  }
}
```

## 🔧 FastAPI Backend

### Ana Endpoint
```python
@app.post("/predict")
async def predict_skin_lesion(
    file: UploadFile = File(...),
    region: Optional[str] = Form(None)
):
    # Görüntüyü işle
    image_bytes = await file.read()
    image_tensor = preprocess_image(image_bytes)
    
    # Model tahmini
    prediction_result = predict_lesion(image_tensor)
    
    return {
        "predicted_class": prediction_result['predicted_class'],
        "confidence": prediction_result['confidence'],
        "all_predictions": prediction_result['all_predictions'],
        "success": True
    }
```

### Model Yükleme
```python
def load_model():
    global model, transform
    
    # MobileNet V2 mimarisini oluştur
    model = models.mobilenet_v2(pretrained=False)
    model.classifier[1] = nn.Linear(model.classifier[1].in_features, 7)
    
    # Eğitilmiş ağırlıkları yükle
    model.load_state_dict(torch.load('mobilenet_skin_96.pt', map_location='cpu'))
    model.eval()
    
    # Veri dönüşüm pipeline'ı
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                           std=[0.229, 0.224, 0.225])
    ])
```

## 🧠 PyTorch Model Eğitimi

### Model Mimarisi
- **Base Model**: MobileNet V2 (ImageNet pretrained)
- **Input Size**: 224x224 RGB
- **Output**: 7 sınıf (cilt lezyonu türleri)
- **Activation**: Softmax

### Eğitim Parametreleri
```python
# Model oluşturma
model = models.mobilenet_v2(pretrained=True)
model.classifier[1] = nn.Linear(model.classifier[1].in_features, 7)

# Eğitim ayarları
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)
scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=10, gamma=0.1)
```

### Veri Artırma
```python
train_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.RandomHorizontalFlip(p=0.5),
    transforms.RandomVerticalFlip(p=0.5),
    transforms.RandomRotation(degrees=20),
    transforms.ColorJitter(brightness=0.2, contrast=0.2),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                       std=[0.229, 0.224, 0.225])
])
```

## 🌐 API Endpoints

### POST /predict
Cilt lezyonu analizi için ana endpoint

**Request:**
```
Content-Type: multipart/form-data
- file: image file (JPG, PNG)
- region: string (optional)
```

**Response:**
```json
{
    "predicted_class": "nv",
    "class_name": "Melanocytic Nevus (Melanositik Nevüs)",
    "confidence": 0.87,
    "risk_level": "Düşük Risk",
    "risk_color": "#10B981",
    "all_predictions": [
        {
            "class": "nv",
            "class_name": "Melanocytic Nevus",
            "probability": 0.87
        },
        ...
    ],
    "region": "Yüz",
    "success": true
}
```

### GET /health
Sistem sağlık kontrolü

**Response:**
```json
{
    "status": "healthy",
    "model_status": "loaded",
    "supported_classes": ["akiec", "bcc", "bkl", "df", "mel", "nv", "vasc"],
    "class_labels": {...}
}
```

## ⚠️ Önemli Notlar

1. **Medikal Uyarı**: Bu sistem sadece bilgilendirme amaçlıdır. Kesin teşhis için mutlaka bir hekime başvurun.

2. **Güvenlik**: Üretim ortamında CORS ayarlarını ve güvenlik önlemlerini uygun şekilde yapılandırın.

3. **Model Performansı**: Model HAM10000 veri seti üzerinde eğitilmiştir. Farklı popülasyonlarda performans değişebilir.

4. **Görüntü Kalitesi**: En iyi sonuçlar için net, gün ışığında çekilmiş görüntüler kullanın.

## 📊 Performans Metrikleri

- **Doğruluk**: ~85-90% (validation set)
- **İşlem Süresi**: ~2-3 saniye per image
- **Model Boyutu**: ~14MB
- **Minimum RAM**: 2GB (inference)

## 🔄 Geliştirme Planları

- [ ] Model performansını artırma
- [ ] Daha fazla cilt lezyonu sınıfı ekleme
- [ ] Batch processing desteği
- [ ] Model versiyonlama
- [ ] A/B testing implementasyonu

## 📄 Lisans

Bu proje eğitim amaçlı hazırlanmıştır. Ticari kullanım için uygun lisans alınmalıdır.

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Değişikliklerinizi commit edin (`git commit -am 'Yeni özellik: açıklama'`)
4. Branch'i push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request oluşturun

## 📞 İletişim

Proje hakkında sorularınız için [GitHub Issues](link) kullanın.

---

**⚕️ DİKKAT**: Bu uygulama tıbbi tanı koymaz. Herhangi bir cilt problemi için mutlaka dermatoloğa başvurun. 
