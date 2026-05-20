# Quick Start Guide - AI Backend

## ✅ Setup Complete!

All dependencies have been installed successfully. You're ready to run the server!

## 🚀 Starting the Server

### Option 1: Using the Start Script (Recommended)
```bash
cd ai-backend
./start_server.sh
```

### Option 2: Manual Start
```bash
cd ai-backend
source venv/bin/activate
python3 main.py
```

## 📍 Server URLs

Once the server is running, you can access:

- **API Server**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## ✅ Verification

To verify the server is working, open a new terminal and run:
```bash
curl http://localhost:8000/health
```

You should see:
```json
{
  "status": "healthy",
  "model_loaded": false,
  "timestamp": "..."
}
```

## 📱 For Flutter App Testing

### ✅ Automatic Configuration (Already Set Up!)

The Flutter app is now configured to automatically use the correct URL:
- **Android Emulator**: Uses `http://10.0.2.2:8000` (automatically detected)
- **iOS Simulator**: Uses `http://localhost:8000` (automatically detected)
- **Physical Device**: See instructions below

### If testing on a physical device:
1. Find your computer's IP address:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # Or
   ipconfig getifaddr en0
   ```

2. Update `lib/config/api_config.dart`:
   ```dart
   static String get baseUrl {
     // For physical device, replace with your IP:
     return 'http://YOUR_IP_ADDRESS:8000';
     // Example: 'http://192.168.1.100:8000'
   }
   ```

3. Make sure your phone and computer are on the same WiFi network

## 🛑 Stopping the Server

Press `Ctrl+C` in the terminal where the server is running.

## 📝 Notes

- The server uses image hashing fallback (TensorFlow is optional)
- All API endpoints are ready:
  - `/ai/register-device` - Register a device
  - `/ai/verify-device` - Verify a device
  - `/ai/check-qr` - Check QR code validity
  - `/health` - Health check

## 🎉 You're All Set!

The backend is ready to work with your Flutter app. Just start the server and test!

