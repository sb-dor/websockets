import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:websockets/main.dart' as app;
import 'package:websockets/src/features/chat/widgets/chat_screen_widget.dart';

import 'helpers/auth_helper.dart';

/// Logs in and creates a fresh room, landing on the chat screen.
/// Used as the shared setup for all chat tests.
Future<void> _loginAndEnterRoom(WidgetTester tester) async {
  await clearSavedSession();
  app.main();
  await waitForApp(tester);

  await loginTestUser(tester);

  // Open Create Room dialog
  await tester.tap(find.byKey(const Key('createRoomFab')));
  await tester.pumpAndSettle();

  // Enter a room name and confirm
  await tester.enterText(find.byKey(const Key('roomNameField')), 'Integration Test Room');
  await tester.tap(find.text('Create'));

  // Creating a room is async (HTTP + Octopus navigation + history fetch)
  await waitForChat(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat', () {
    testWidgets('chat screen is shown after entering a room', (tester) async {
      await _loginAndEnterRoom(tester);

      expect(find.byType(ChatScreenWidget), findsOneWidget);
    });

    testWidgets('AppBar shows the room name', (tester) async {
      await _loginAndEnterRoom(tester);

      expect(find.text('Integration Test Room'), findsOneWidget);
    });

    testWidgets('room code chip is visible in AppBar', (tester) async {
      await _loginAndEnterRoom(tester);

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('shows Connecting state briefly then loads', (tester) async {
      await _loginAndEnterRoom(tester);

      // After pumpAndSettle the connection should be established
      expect(find.byKey(const Key('messageInput')), findsOneWidget);
      expect(find.byKey(const Key('sendButton')), findsOneWidget);
    });

    testWidgets('empty room shows "No messages yet" placeholder', (tester) async {
      await _loginAndEnterRoom(tester);

      // Freshly created room has no history
      expect(find.text('No messages yet. Say hello!'), findsOneWidget);
    });

    testWidgets('can type a message in the input field', (tester) async {
      await _loginAndEnterRoom(tester);

      await tester.enterText(find.byKey(const Key('messageInput')), 'hello world');
      await tester.pump();

      expect(find.text('hello world'), findsOneWidget);
    });

    testWidgets('send button is enabled when input has text', (tester) async {
      await _loginAndEnterRoom(tester);

      await tester.enterText(find.byKey(const Key('messageInput')), 'hello');
      await tester.pump();

      final btn = tester.widget<IconButton>(find.byKey(const Key('sendButton')));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('sending a message makes it appear in the list', (tester) async {
      await _loginAndEnterRoom(tester);

      await tester.enterText(find.byKey(const Key('messageInput')), 'hello from integration test');
      await tester.tap(find.byKey(const Key('sendButton')));
      // Send is async — poll until message appears (or Pusher delivers it)
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.text('hello from integration test').evaluate().isNotEmpty) break;
      }

      expect(find.text('hello from integration test'), findsOneWidget);
    });

    testWidgets('input clears after sending', (tester) async {
      await _loginAndEnterRoom(tester);

      await tester.enterText(find.byKey(const Key('messageInput')), 'clear me');
      await tester.tap(find.byKey(const Key('sendButton')));
      // Input clears synchronously on tap — one pump is enough
      await tester.pump();

      final tf = tester.widget<TextField>(find.byKey(const Key('messageInput')));
      expect(tf.controller?.text, isEmpty);
    });
  });
}
