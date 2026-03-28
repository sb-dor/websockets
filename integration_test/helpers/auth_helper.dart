import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:websockets/src/features/authentication/widget/signin_screen.dart';
import 'package:websockets/src/features/lobby/widgets/lobby_screen_widget.dart';

// ---------------------------------------------------------------------------
// Configure these credentials to match a real account on your backend.
// ---------------------------------------------------------------------------
const kTestEmail = 'test@gmail.com';
const kTestPassword = '123456';
const kTestName = 'Test User';

/// Clears SharedPreferences so there is no saved auth token.
/// Call this BEFORE [app.main()] to guarantee the sign-in screen appears.
Future<void> clearSavedSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

/// Polls until either [SignInScreen] or [LobbyScreenWidget] is visible,
/// or throws after [maxSeconds] seconds.
///
/// Needed because app init uses [deferFirstFrame] — [pumpAndSettle] returns
/// before [runApp] is called, so we must drive frames manually until the
/// first real screen appears.
Future<void> waitForApp(WidgetTester tester, {int maxSeconds = 30}) async {
  for (var i = 0; i < maxSeconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(SignInScreen).evaluate().isNotEmpty ||
        find.byType(LobbyScreenWidget).evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  throw Exception('App did not reach a known screen after ${maxSeconds}s');
}

/// Polls until [LobbyScreenWidget] is visible.
/// Use after tapping Login — the HTTP request is async so [pumpAndSettle]
/// alone returns before the response arrives.
Future<void> waitForLobby(WidgetTester tester, {int maxSeconds = 30}) async {
  for (var i = 0; i < maxSeconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(LobbyScreenWidget).evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  // Collect all visible Text widgets to show what's on screen when we timed out
  final visibleTexts = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .where((t) => t.isNotEmpty)
      .toList();
  throw Exception(
    'Lobby screen did not appear after ${maxSeconds}s.\n'
    'Visible text on screen: $visibleTexts\n'
    'Hint: check that your backend is running and that '
    'kTestEmail/kTestPassword match a real account.',
  );
}

/// Polls until the chat message input [Key('messageInput')] is visible.
/// Use after creating/joining a room — navigation + history fetch are async.
Future<void> waitForChat(WidgetTester tester, {int maxSeconds = 30}) async {
  for (var i = 0; i < maxSeconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('messageInput')).evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  throw Exception('Chat screen did not appear after ${maxSeconds}s');
}

/// Logs in with [kTestEmail] / [kTestPassword] and waits until lobby appears.
/// Assumes [waitForApp] has already been called and sign-in screen is visible.
Future<void> loginTestUser(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('emailField')), kTestEmail);
  await tester.enterText(find.byKey(const Key('passwordField')), kTestPassword);
  // pump() so the widget rebuilds and FilledButton.onPressed becomes non-null
  await tester.pump();
  await tester.tap(find.byKey(const Key('submitButton')));
  await waitForLobby(tester);
}

/// Registers a new account then waits until lobby appears.
/// Assumes sign-in screen is visible.
Future<void> registerTestUser(WidgetTester tester) async {
  await tester.tap(find.text('Register'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('nameField')), kTestName);
  await tester.enterText(find.byKey(const Key('emailField')), kTestEmail);
  await tester.enterText(find.byKey(const Key('passwordField')), kTestPassword);
  await tester.tap(find.byKey(const Key('submitButton')));
  await waitForLobby(tester);
}
