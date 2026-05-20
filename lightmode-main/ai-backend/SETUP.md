# AI Backend Setup Guide

## Quick Setup (Python 3.13 Compatible)

### Step 1: Create Virtual Environment
```bash
cd ai-backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### Step 2: Install Dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 3: Run the Server
```bash
python3 main.py
# Or with uvicorn directly:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Troubleshooting

### If you get "python: command not found"
- Use `python3` instead of `python` on macOS
- Check your Python version: `python3 --version`

### If numpy installation fails
- The requirements.txt now uses compatible versions for Python 3.13
- If issues persist, try: `pip install numpy --upgrade`

### TensorFlow is Optional
- The backend works without TensorFlow using image hashing fallback
- If you want TensorFlow features, install separately:
  ```bash
  pip install tensorflow
  ```

## Verify Installation

1. Start the server: `python3 main.py`
2. Check health: `curl http://localhost:8000/health`
3. Should see: `{"status": "healthy"}`

## Default Port

The server runs on `http://localhost:8000` by default.

Make sure this matches your `NEXT_PUBLIC_AI_API_URL` environment variable in the frontend.

