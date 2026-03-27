# Planfinity Production Deployment Guide

## 1) Backend Environment

Create `backend/.env` from `backend/.env.example` and fill real values:

- `MONGO_URL`
- `JWT_SECRET`
- `OPENAI_API_KEY`
- `FIREBASE_CREDENTIALS_PATH`
- `CORS_ORIGINS`

## 2) Backend Run Command

Use:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 10000
```

Or use `backend/start.sh`.

## 3) Render Deployment

- Root dir: `backend`
- Build command: `pip install -r requirements.txt`
- Start command: `uvicorn app.main:app --host 0.0.0.0 --port 10000`
- Add env vars from `.env` in Render dashboard

A starter `backend/render.yaml` is included.

## 4) Flutter API Endpoint

Default API endpoint is now cloud-ready and can be overridden at build time:

```bash
flutter run --dart-define=API_BASE_URL=https://your-app.onrender.com
```

## 5) Android Network Permission

`android.permission.INTERNET` is enabled in Android manifest.

## 6) Release Build

```bash
flutter build apk --release
```

Output:

`build/app/outputs/flutter-apk/app-release.apk`

## 7) Optional Play Store Bundle

```bash
flutter build appbundle
```

## 8) Launcher Icon

Add image file at `assets/icon.png`, then run:

```bash
flutter pub run flutter_launcher_icons
```
