// Single entry point that runs all integration tests in one app session.
// Use this instead of running files separately on macOS/desktop:
//
//   flutter test integration_test/all_tests.dart -d macos \
//     --dart-define-from-file=config/production.json
//
// Running separate files back-to-back on macOS fails because the second
// file cannot start the app while the first session is still alive.

import 'auth_test.dart' as auth;
import 'chat_test.dart' as chat;
import 'lobby_test.dart' as lobby;

void main() {
  auth.main();
  lobby.main();
  chat.main();
}
