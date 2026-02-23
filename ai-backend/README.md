# SecureGate AI Backend

Python FastAPI backend for device verification, image matching, and QR code anti-forgery detection.

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the server:
```bash
python main.py
# Or with uvicorn directly:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

- `POST /ai/register-device` - Register a device and extract features
- `POST /ai/verify-device` - Verify a device with live image
- `POST /ai/check-qr` - Check QR code validity
- `POST /ai/generate-features` - Generate features from image
- `GET /health` - Health check

## Environment Variables

Set `NEXT_PUBLIC_AI_API_URL` in your frontend to point to this backend (default: http://localhost:8000)

## Notes

- MobileNetV2 model is loaded for feature extraction
- Falls back to image hashing if model fails to load
- In production, store device features in database for comparison

