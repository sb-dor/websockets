# Integration Tests

End-to-end tests that run the full app on a real device/simulator against a live backend.

## Prerequisites

1. **Backend running** — Laravel + Reverb must be up:
   ```bash
   php artisan serve --host=0.0.0.0
   php artisan reverb:start
   ```

2. **Test account exists** — the credentials in `helpers/auth_helper.dart` must match a real account on the backend:
   ```dart
   const kTestEmail = 'test@gmail.com';
   const kTestPassword = '123456';
   ```

3. **Device connected** — simulator, emulator, or physical device. List available devices:
   ```bash
   flutter devices
   ```

## Running tests

> ⚠️ Always pass `--dart-define-from-file` — without it the app points to `localhost:8000` instead of your real backend URL.

### All tests (recommended)

```bash
flutter test integration_test/all_tests.dart -d macos \
  --dart-define-from-file=config/production.json
```

### One feature at a time

```bash
flutter test integration_test/auth_test.dart -d macos \
  --dart-define-from-file=config/production.json

flutter test integration_test/lobby_test.dart -d macos \
  --dart-define-from-file=config/production.json

flutter test integration_test/chat_test.dart -d macos \
  --dart-define-from-file=config/production.json
```

> **Note (macOS/desktop):** Running multiple files in one command (`flutter test integration_test/`) fails on macOS because the second file can't start the app while the first session is still alive. Use `all_tests.dart` to run everything in a single session.

## Test structure

```
integration_test/
  helpers/
    auth_helper.dart   — shared helpers: clearSavedSession, waitForApp,
                         waitForLobby, waitForChat, loginTestUser
  auth_test.dart       — sign-in screen, button state, login, register tab
  lobby_test.dart      — lobby after login, room list, create/join dialogs
  chat_test.dart       — enter room, send message, input clears
  all_tests.dart       — single entry point that runs all three files
```

## How it works

Each test:
1. Calls `clearSavedSession()` — wipes SharedPreferences so no stale auth token causes the app to skip sign-in
2. Calls `app.main()` — launches the real app
3. Calls `waitForApp()` — polls until sign-in or lobby screen appears (needed because app init uses `deferFirstFrame`)
4. Proceeds with the test scenario using real network calls — no mocks
