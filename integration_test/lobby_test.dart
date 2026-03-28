import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:websockets/main.dart' as app;
import 'package:websockets/src/features/lobby/widgets/lobby_screen_widget.dart';

import 'helpers/auth_helper.dart';

Future<void> _loginToLobby(WidgetTester tester) async {
  await clearSavedSession();
  app.main();
  await waitForApp(tester);
  await loginTestUser(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lobby', () {
    testWidgets('lobby screen is shown after login', (tester) async {
      await _loginToLobby(tester);

      expect(find.byType(LobbyScreenWidget), findsOneWidget);
    });

    testWidgets('lobby shows room list or empty state after loading', (tester) async {
      await _loginToLobby(tester);

      // Either rooms loaded or empty state — either way no error and no spinner
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final hasRooms = find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey &&
                (w.key! as ValueKey).value.toString().startsWith('room_'),
          )
          .evaluate()
          .isNotEmpty;
      final hasEmptyState =
          find.text('No rooms yet.\nCreate one or join with a code.').evaluate().isNotEmpty;
      expect(hasRooms || hasEmptyState, isTrue);
    });

    testWidgets('Create Room FAB opens dialog', (tester) async {
      await _loginToLobby(tester);

      await tester.tap(find.byKey(const Key('createRoomFab')));
      await tester.pumpAndSettle();

      expect(find.text('Create Room'), findsWidgets);
      expect(find.byKey(const Key('roomNameField')), findsOneWidget);
    });

    testWidgets('Create Room dialog cancel closes without navigating', (tester) async {
      await _loginToLobby(tester);

      await tester.tap(find.byKey(const Key('createRoomFab')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(LobbyScreenWidget), findsOneWidget);
    });

    testWidgets('creating a room navigates to chat', (tester) async {
      await _loginToLobby(tester);

      await tester.tap(find.byKey(const Key('createRoomFab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('roomNameField')), 'Test Room');
      await tester.tap(find.text('Create'));

      // Creating a room is async (HTTP + Octopus navigation + history fetch)
      await waitForChat(tester);

      expect(find.byKey(const Key('messageInput')), findsOneWidget);
    });

    testWidgets('Join Room FAB opens dialog', (tester) async {
      await _loginToLobby(tester);

      await tester.tap(find.byKey(const Key('joinRoomFab')));
      await tester.pumpAndSettle();

      expect(find.text('Join Room'), findsWidgets);
      expect(find.byKey(const Key('roomCodeField')), findsOneWidget);
    });

    testWidgets('Join Room dialog cancel closes without navigating', (tester) async {
      await _loginToLobby(tester);

      await tester.tap(find.byKey(const Key('joinRoomFab')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(LobbyScreenWidget), findsOneWidget);
    });
  });
}
