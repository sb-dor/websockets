## Get Started

### Requirements
- Flutter 3.x+
- Dart 3.x+
- Android device/emulator on the same local network as the backend

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Configure the backend URL

Edit `config/development.json` and set your server's local IP:
```json
{
  "API_BASE_URL": "http://192.168.100.96:8000",
  "WS_KEY": "must_match_REVERB_APP_KEY_in_laravel_env",
  "WS_HOST": "192.168.100.96",
  "WS_PORT": 8080,
  "WS_TLS": false
}
```

### 3. Run the app
```bash
flutter run --dart-define-from-file=config/development.json
```

> **Note:** `WS_KEY` must be the same value as `REVERB_APP_KEY` in the Laravel `.env`. Both are strings you make up yourself — just keep them in sync.

Make sure the Laravel HTTP server (port 8000) and Reverb WebSocket server (port 8080) are both running before launching the app.

---

## Rename the project (optional)

```bash
dart run tool/dart/rename_project.dart --name="project" --organization="dev.flutter" --description="My project description"
```
