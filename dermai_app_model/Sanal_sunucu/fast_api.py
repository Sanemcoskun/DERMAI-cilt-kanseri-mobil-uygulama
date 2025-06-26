from fastapi import FastAPI, File, UploadFile
from PIL import Image
import torch
import torchvision.transforms as transforms
import io

app = FastAPI()

# Model yükleme
MODEL_PATH = "mobilenet_skin_96.pt"
device = torch.device('cpu')

# MobileNetV2 modelini oluştur
model = torch.hub.load('pytorch/vision:v0.10.0', 'mobilenet_v2', pretrained=False)
model.classifier[1] = torch.nn.Linear(model.classifier[1].in_features, 7)  # 7 sınıf için

# Eğitilmiş model ağırlıklarını yükle
state_dict = torch.load(MODEL_PATH, map_location=device)
model.load_state_dict(state_dict)
model.to(device)
model.eval()

# Sınıf isimleri
CLASS_NAMES = ["akiec", "bcc", "bkl", "df", "mel", "nv", "vasc"]# Görüntü ön işleme
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225])
])

@app.post("/predict")
async def predict_image(file: UploadFile = File(...)):
    image_data = await file.read()
    image = Image.open(io.BytesIO(image_data))

    if image.mode != "RGB":
        image = image.convert("RGB")

    image_tensor = transform(image).unsqueeze(0)

    with torch.no_grad():
        outputs = model(image_tensor)
        _, predicted = torch.max(outputs, 1)
        probabilities = torch.nn.functional.softmax(outputs[0], dim=0) predicted_class = CLASS_NAMES[predicted.item()]
    confidence = float(probabilities[predicted].item())

    return {
        "predicted_class": predicted_class,
        "confidence": confidence,
        "probabilities": {
            class_name: float(prob)
            for class_name, prob in zip(CLASS_NAMES, probabilities.tolist())
        }
    }
